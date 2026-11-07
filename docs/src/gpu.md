# GPU and calibration

The pricers, the Greeks and the implied volatility are plain scalar functions without allocations, so they broadcast
over GPU arrays as they are: a broadcast over `CuArray`s ([CUDA.jl](https://github.com/JuliaGPU/CUDA.jl)) compiles
to a single GPU kernel, with no scalar indexing. Every option of a smile, a surface or a book is priced, or inverted,
in parallel.

```julia
using FinancialToolbox, CUDA
S0, r, T, d = 100.0f0, 0.02f0, 1.2f0, 0.01f0
K = cu(collect(range(70.0f0, 140.0f0, length = 10^6)))  # a million strikes on the GPU
prices = blsprice.(S0, K, r, T, 0.2f0, d)                # CuArray
vols = blsimpv.(S0, K, r, T, prices, d)                  # CuArray, all equal to 0.2f0
```

The same works with any GPU array type (AMDGPU.jl, Metal.jl, oneAPI.jl), since only broadcasting is involved. The test
suite runs it on [JLArrays.jl](https://github.com/JuliaGPU/GPUArrays.jl), the reference GPU array of GPUArrays, and on
CUDA.

## Automatic differentiation on the GPU

Calibrating a model means minimising a loss over many quoted options, with the gradient of the loss with respect to
the parameters, and sometimes with respect to the data. These AD backends differentiate broadcasts over `CuArray`s:

| Backend | Derivative with respect to a parameter | Gradient with respect to a GPU array |
|:--|:--|:--|
| [Zygote.jl](https://github.com/FluxML/Zygote.jl) | yes | yes |
| [Mooncake.jl](https://github.com/chalk-lab/Mooncake.jl) | yes | yes |
| [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) | yes | one dual number per element (see below) |
| [DualNumbers.jl](https://github.com/JuliaDiff/DualNumbers.jl) | yes | one dual number per element |
| [Enzyme.jl](https://github.com/EnzymeAD/Enzyme.jl) | inside a kernel, for the pricers and the Greeks | not yet for the implied volatility (see below) |

Zygote uses the rules of the package for the broadcasts of `blsprice`, `blkprice`, `blsimpv` and `blkimpv`: a single
kernel computes the values and every partial derivative in closed form, and only the gradients that are needed are
reduced. Without them Zygote would rerun the broadcast once per argument.

Two limitations come from the AD packages, not from this one:
- `ForwardDiff.gradient` does not support GPU arrays ([ForwardDiff.jl#759](https://github.com/JuliaDiff/ForwardDiff.jl/issues/759)).
  When every output depends on its own input only, as the implied volatility of each option on its own price, the
  derivative of each element is a single dual number:
  `map((k, p) -> ForwardDiff.derivative(q -> blsimpv(S0, k, r, T, q, d), p), K, prices)` is one kernel.
- Enzyme custom rules do not compile inside CUDA kernels yet when their code calls special functions
  ([Enzyme.jl#3962](https://github.com/EnzymeAD/Enzyme.jl/issues/3962)), and the implied volatility relies on one.

## A calibration

A smile with an implied volatility quadratic in the log-moneyness,

```math
\sigma_\theta(K) = a + b \log^2\frac{K}{F}, \qquad \theta = (a, b), \qquad F = S_0 e^{(r - d)T},
```

is fitted to the market prices ``m_1, \dots, m_n`` of calls with strikes ``K_1, \dots, K_n`` by least squares on the
pricing errors

```math
e_i(\theta) = C_{bs}(S_0, K_i, r, T, \sigma_\theta(K_i), d) - m_i, \qquad
L(\theta, m) = \frac{1}{2} \sum_{i=1}^n e_i(\theta)^2 .
```

Gauss–Newton ([Nocedal and Wright](references.md#Calibration)) linearises the errors around the current parameters, ``e(\theta + \delta) \approx e(\theta) + J \delta``
with ``J = \partial_\theta e`` the ``n \times 2`` Jacobian, and takes the step that minimises the linearised loss, the
least squares solution of

```math
J \, \delta = -e(\theta).
```

Zygote computes ``J`` through the broadcast rule of `blsprice`, and `J \ e` solves the least squares problem. The
quotes are generated from ``a = 0.18``, ``b = 0.4``, plus some noise that no smile of this family fits exactly.

```@example calibration
using FinancialToolbox, Zygote, ForwardDiff
S0, r, T, d = 100.0, 0.02, 1.0, 0.01
F = S0 * exp((r - d) * T)
strikes = collect(range(70.0, 140.0, length = 200))
smile(a, b, K) = a + b * log(K / F)^2
market = blsprice.(S0, strikes, r, T, smile.(0.18, 0.4, strikes), d) .+ 0.05 .* sin.(1:200)

pricing_errors(θ, m) = blsprice.(S0, strikes, r, T, smile.(θ[1], θ[2], strikes), d) .- m
function calibrate(m)
    θ = [0.25, 0.0]
    for _ in 1:8
        J = only(Zygote.jacobian(t -> pricing_errors(t, m), θ))
        θ -= J \ pricing_errors(θ, m)
    end
    return θ
end
θ = calibrate(market)
```

The implied volatilities of the quotes, and their sensitivities to the prices (the inverse of the vegas), on the
same footing:

```@example calibration
vols = blsimpv.(S0, strikes, r, T, market, d)
dvols = only(Zygote.gradient(p -> sum(blsimpv.(S0, strikes, r, T, p, d)), market))
extrema(vols), dvols[1:3] ≈ inv.(blsvega.(S0, strikes[1:3], r, T, vols[1:3], d))
```

### Sensitivity of the calibrated parameters to the quotes

How do the calibrated parameters ``\theta^*(m)`` move when a quote moves? At the optimum the gradient of the loss
vanishes,

```math
g(\theta^*, m) = \partial_\theta L(\theta^*, m) = J^\top e(\theta^*) = 0 .
```

By the implicit function theorem ([Dini's theorem](references.md#Implicit-function-theorem)), where ``\partial_\theta g`` is invertible this defines
``\theta^*(m)``, with

```math
\frac{\partial \theta^*}{\partial m} = -\left(\partial_\theta g\right)^{-1} \partial_m g = H^{-1} J^\top,
\qquad H = \partial^2_\theta L = J^\top J + \sum_{i=1}^n e_i \, \partial^2_\theta e_i ,
```

since ``\partial_m g = -J^\top`` (each ``e_i`` depends on ``m_i`` with derivative ``-1``). ``H`` is the Hessian of the
loss: ForwardDiff computes it through the broadcasts. When the quotes are fitted exactly the errors vanish, ``H =
J^\top J`` and the sensitivities are the pseudo-inverse ``(J^\top J)^{-1} J^\top``; with fitting errors the second
term counts. No recalibration is needed: the ``2 \times n`` matrix of sensitivities comes from the derivatives at the
optimum.

```@example calibration
J = only(Zygote.jacobian(t -> pricing_errors(t, market), θ))
H = ForwardDiff.hessian(t -> sum(abs2, pricing_errors(t, market)) / 2, θ)
sensitivities = H \ transpose(J)    # ∂θ*/∂m, 2 × 200
size(sensitivities)
```

A check on one quote, against recalibrating after bumping it, and against the pseudo-inverse, which ignores the
fitting errors:

```@example calibration
i, h = 120, 1e-5
bumped = copy(market)
bumped[i] += h
(implicit = sensitivities[:, i], recalibrated = (calibrate(bumped) - θ) / h, pseudo_inverse = ((transpose(J) * J) \ transpose(J))[:, i])
```

The example runs on the CPU, so that it runs when this documentation is built. On a GPU, move the strikes and the
quotes with `cu` and put the code in a function (closures over global variables cannot be compiled for the GPU): the
Jacobian, the Hessian and the broadcasts run there unchanged.


## Performance

Time of the broadcasts and of their derivatives over `n` options, on the CPU (one thread) and on the GPU, with the
allocations: only the arrays of the results, on both. ForwardDiff differentiates the loss of a calibration with respect
to σ, Zygote the sum of the implied volatilities with respect to the prices. Measured with
[`benchmark/gpu/run.jl`](https://github.com/rcalxrc08/FinancialToolbox.jl/blob/master/benchmark/gpu/run.jl) on an Intel i7-8550U and an NVIDIA GeForce MX150, a laptop GPU whose `Float64` throughput is 1/32 of its `Float32` one:
data-center GPUs narrow the gap between the two.

| Operation | Type | n | CPU | GPU | Speedup |
|:--|:--|--:|--:|--:|--:|
| `blsprice` | Float32 | 10⁴ | 829 μs | 38 μs | 22× |
| `blsimpv` | Float32 | 10⁴ | 2.66 ms | 64 μs | 42× |
| ForwardDiff, calibration loss | Float32 | 10⁴ | 1.19 ms | 157 μs | 7.6× |
| Zygote, gradient w.r.t. the prices | Float32 | 10⁴ | 3.52 ms | 283 μs | 12× |
| `blsprice` | Float32 | 10⁶ | 91.6 ms | 642 μs | 143× |
| `blsimpv` | Float32 | 10⁶ | 291 ms | 2.38 ms | 123× |
| ForwardDiff, calibration loss | Float32 | 10⁶ | 108 ms | 3.95 ms | 27× |
| Zygote, gradient w.r.t. the prices | Float32 | 10⁶ | 342 ms | 7.81 ms | 44× |
| `blsprice` | Float64 | 10⁶ | 104 ms | 13.7 ms | 7.6× |
| `blsimpv` | Float64 | 10⁶ | 382 ms | 53.5 ms | 7.1× |
| ForwardDiff, calibration loss | Float64 | 10⁶ | 124 ms | 18.0 ms | 6.9× |
| Zygote, gradient w.r.t. the prices | Float64 | 10⁶ | 467 ms | 71.8 ms | 6.5× |

Below about a thousand options the fixed cost of launching the kernels and of copying the reductions back to the host,
about 100 μs on this machine, is comparable to the work: there the CPU is as fast.
