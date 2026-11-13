```@raw html
<div class="fc-page-head">
<p class="fc-kicker"><span>Guide 04</span> One kernel per broadcast</p>
```

# GPU and calibration

The pricers, the Greeks and the implied volatility are plain scalar functions without allocations, so they broadcast
over GPU arrays as they are: a broadcast over `CuArray`s ([CUDA.jl](https://github.com/JuliaGPU/CUDA.jl)) compiles
to a single GPU kernel, with no scalar indexing. Every option of a smile, a surface or a book is priced, or inverted,
in parallel.

```@raw html
<div class="fc-meta"><span>CUDA</span><span>Zygote</span><span>calibration</span><span>implicit function theorem</span><span class="is-live">computed at build time</span></div>
<nav class="fc-toc">
<a href="#Automatic-differentiation-on-the-GPU"><b>01</b>Automatic differentiation on the GPU</a>
<a href="#A-calibration"><b>02</b>A calibration</a>
<a href="#Performance"><b>03</b>Performance</a>
</nav>
</div>
```

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

Smiles are usually calibrated on implied volatilities rather than on prices: the errors of all the strikes are then on
the same scale. The market quotes prices ``m_1, \dots, m_n`` of calls with strikes ``K_1, \dots, K_n``; their implied
volatilities ``v_i`` are a single broadcast of [`blsimpv`](@ref). The model is a smile of the SVI family, in total
variance ``w = \sigma^2 T`` as a function of the log-moneyness ``k = \log(K / F)``,

```math
w_\theta(k) = a + b \left(\rho \, k + \sqrt{k^2 + s^2}\right), \qquad \sigma_\theta(K) = \sqrt{\frac{w_\theta(k)}{T}},
\qquad \theta = (a, b, \rho), \qquad F = S_0 e^{(r - d)T},
```

with ``s = 0.1`` fixed, and it is fitted by least squares on the volatility errors

```math
e_i(\theta) = \sigma_\theta(K_i) - v_i, \qquad L(\theta, v) = \frac{1}{2} \sum_{i=1}^n e_i(\theta)^2 .
```

Gauss–Newton ([Nocedal and Wright](references.md#Calibration)) linearises the errors around the current parameters,
``e(\theta + \delta) \approx e(\theta) + J \delta`` with ``J = \partial_\theta e`` the ``n \times 3`` Jacobian, and
takes the least squares solution of

```math
J \, \delta = -e(\theta).
```

Zygote computes ``J``, and `J \ e` solves the least squares problem. The quotes are generated from
``\theta = (0.02, 0.1, -0.4)``, with prices off by up to 1%, which no smile of the family fits exactly.

```@example calibration
using FinancialToolbox, Zygote, ForwardDiff
S0, r, T, d = 100.0, 0.02, 1.0, 0.01
F = S0 * exp((r - d) * T)
strikes = collect(range(70.0, 140.0, length = 200))
smile_vol(a, b, ρ, K) = sqrt((a + b * (ρ * log(K / F) + sqrt(log(K / F)^2 + 0.01))) / T)
market_prices = blsprice.(S0, strikes, r, T, smile_vol.(0.02, 0.1, -0.4, strikes), d) .* (1 .+ 0.01 .* sin.(1:200))

market_vols(m) = blsimpv.(S0, strikes, r, T, m, d)
vol_errors(θ, v) = smile_vol.(θ[1], θ[2], θ[3], strikes) .- v
function calibrate(v)
    θ = [0.03, 0.05, 0.0]
    for _ in 1:15
        J = only(Zygote.jacobian(t -> vol_errors(t, v), θ))
        θ -= J \ vol_errors(θ, v)
    end
    return θ
end
v = market_vols(market_prices)
θ = calibrate(v)
```

### Sensitivity of the calibrated parameters to the quotes

How do the calibrated parameters ``\theta^*`` move when a quoted price moves? Two functions are defined implicitly
here, and the implicit function theorem ([Dini's theorem](references.md#Implicit-function-theorem)) gives the
derivatives of both without differentiating either solver.

The parameters, as functions of the volatilities: at the optimum the gradient of the loss vanishes,

```math
g(\theta^*, v) = \partial_\theta L(\theta^*, v) = J^\top e(\theta^*) = 0,
```

and where ``\partial_\theta g`` is invertible

```math
\frac{\partial \theta^*}{\partial v} = -\left(\partial_\theta g\right)^{-1} \partial_v g = H^{-1} J^\top,
\qquad H = \partial^2_\theta L = J^\top J + \sum_{i=1}^n e_i \, \partial^2_\theta e_i ,
```

since ``\partial_v g = -J^\top``. ``H`` is the Hessian of the loss, from ForwardDiff. When the volatilities are fitted
exactly the errors vanish, ``H = J^\top J``, and the sensitivities are the pseudo-inverse ``(J^\top J)^{-1} J^\top``;
with fitting errors the second term counts.

The volatilities, as functions of the prices: ``v_i`` solves ``C_{bs}(S_0, K_i, r, T, v_i, d) = m_i``, so

```math
\frac{\partial v_i}{\partial m_i} = \frac{1}{\nu_i}, \qquad \nu_i = \partial_\sigma C_{bs}(S_0, K_i, r, T, v_i, d),
```

the inverse of the vega, and ``\partial v_i / \partial m_j = 0`` for ``i \neq j``. This is how the AD rules of
[`blsimpv`](@ref) differentiate it ([Automatic differentiation](ad.md#Derivatives-of-the-implied-volatility)), so
Zygote returns the ``1/\nu_i`` through the broadcast. By the chain rule,

```math
\frac{\partial \theta^*}{\partial m} = H^{-1} J^\top \operatorname{diag}\left(\frac{1}{\nu_1}, \dots, \frac{1}{\nu_n}\right).
```

No recalibration is needed: the ``3 \times n`` matrix of sensitivities comes from derivatives at the optimum.

```@example calibration
J = only(Zygote.jacobian(t -> vol_errors(t, v), θ))
H = ForwardDiff.hessian(t -> sum(abs2, vol_errors(t, v)) / 2, θ)
∂v_∂m = only(Zygote.gradient(m -> sum(market_vols(m)), market_prices))  # the diagonal, 1 ./ vegas
∂θ_∂m = (H \ transpose(J)) .* transpose(∂v_∂m)                       # 3 × 200
∂v_∂m[1:3] ≈ inv.(blsvega.(S0, strikes[1:3], r, T, v[1:3], d))
```

A check on one quote, against bumping its price, implying the volatilities again and recalibrating, and against the
pseudo-inverse, which ignores the fitting errors:

```@example calibration
i, h = 120, 1e-6
bumped = copy(market_prices)
bumped[i] += h
(implicit = ∂θ_∂m[:, i], recalibrated = (calibrate(market_vols(bumped)) - θ) / h, pseudo_inverse = (((transpose(J) * J) \ transpose(J)) .* transpose(∂v_∂m))[:, i])
```

The example runs on the CPU, so that it runs when this documentation is built. On a GPU, move the strikes and the
quotes with `cu`, put the code in a function (closures over global variables cannot be compiled for the GPU), and bring
the small results back with `Array`: the step `Array(J \ vol_errors(θ, v))` and `Array(∂v_∂m)`. The implied
volatilities, the broadcasts and their derivatives run on the GPU; the ``3 \times 3`` and ``3 \times n`` algebra on
the CPU.

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
