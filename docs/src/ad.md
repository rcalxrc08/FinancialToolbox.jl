```@raw html
<div class="fc-page-head">
<p class="fc-kicker"><span>Guide 03</span> Every backend, every order</p>
```

# Automatic differentiation

Pricers and sensitivities are plain Julia code, differentiable by any AD engine capable of differentiating the `erfc`
function (rules for `erfc` are provided for TaylorSeries and TaylorDiff). The implied volatility is never
differentiated through the numerical solver: its derivatives are defined analytically, as shown below.

```@raw html
<div class="fc-meta"><span>ForwardDiff</span><span>Zygote</span><span>Mooncake</span><span>Enzyme</span><span>TaylorSeries</span><span class="is-live">computed at build time</span></div>
<nav class="fc-toc">
<a href="#Examples"><b>01</b>Examples</a>
<a href="#Derivatives-of-the-implied-volatility"><b>02</b>Derivatives of the implied volatility</a>
</nav>
</div>
```

| Support | Backends |
|:--|:--|
| ChainRulesCore `frule` and `rrule` | [Zygote.jl](https://github.com/FluxML/Zygote.jl), [ReverseDiff.jl](https://github.com/JuliaDiff/ReverseDiff.jl), [Mooncake.jl](https://github.com/chalk-lab/Mooncake.jl) (forward and reverse mode) |
| Native rules, in package extensions | [Enzyme.jl](https://github.com/EnzymeAD/Enzyme.jl) (forward, reverse and batched modes), [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl), [DualNumbers.jl](https://github.com/JuliaDiff/DualNumbers.jl), [HyperDualNumbers.jl](https://github.com/JuliaDiff/HyperDualNumbers.jl), [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl) |
| Taylor series of any order | [TaylorSeries.jl](https://github.com/JuliaDiff/TaylorSeries.jl) (`Taylor1`, `TaylorN` and nested), [TaylorDiff.jl](https://github.com/JuliaDiff/TaylorDiff.jl) |

If your AD package is not supported, please [open an issue](https://github.com/rcalxrc08/FinancialToolbox.jl/issues).

## Examples

The gradient of the implied volatility with respect to all the inputs, with ForwardDiff:

```@example ad
using FinancialToolbox, ForwardDiff
S = 100.0; K = 100.0; r = 0.02; T = 1.2; d = 0.01
price = blsprice(S, K, r, T, 0.2, d)
ForwardDiff.gradient(x -> blsimpv(x...), [S, K, r, T, price, d])
```

and in reverse mode, with Mooncake:

```@example ad
using Mooncake
cache = Mooncake.prepare_gradient_cache(blsimpv, S, K, r, T, price, d)
σ, (_, ∂S, ∂K, ∂r, ∂T, ∂price, ∂d) = Mooncake.value_and_gradient!!(cache, blsimpv, S, K, r, T, price, d)
```

The derivative with respect to the price is the inverse of the vega:

```@example ad
∂price ≈ 1 / blsvega(S, K, r, T, σ, d)
```

The Taylor expansion of the implied volatility as a function of the price, up to order 5, with TaylorSeries:

```@example ad
using TaylorSeries
blsimpv(S, K, r, T, price + Taylor1(5), d)
```

## Derivatives of the implied volatility

In the Black and Scholes model let ``f(S, K, r, T, \sigma, d)`` be the price of the call, ``C_{bs}``, or of the put,
``P_{bs}``, and fix a feasible option price ``V``. Since ``\sigma = \sigma(S, K, r, T, V, d)`` solves the inversion,

```math
f(S, K, r, T, \sigma(S, K, r, T, V, d), d) = V.
```

Differentiating both sides with respect to a generic parameter ``	heta`` (the implicit function theorem,
[Dini's theorem](references.md#Implicit-function-theorem)) gives

```math
\partial_{\theta}\sigma = \frac{\partial_{\theta}\left(V - f(S, K, r, T, \sigma, d)\right)}{\partial_{\sigma}f(S, K, r, T, \sigma, d)}.
```

The same applies to the Black model, with ``f`` the price ``C_{bk}`` or ``P_{bk}``:

```math
\partial_{\theta}\sigma = \frac{\partial_{\theta}\left(V - f(F, K, r, T, \sigma)\right)}{\partial_{\sigma}f(F, K, r, T, \sigma)}.
```

This formulation defines analytically the `frule` and the `rrule` of [`blsimpv`](@ref) and [`blkimpv`](@ref),
without differentiating the numerical solver.

The figure shows these derivatives for a call whose price corresponds to ``\sigma = 20\%``, as functions of the
strike, computed with ForwardDiff through [`blsimpv`](@ref), one panel per input. All of them are proportional to the
inverse of the vega, so they grow in magnitude where the vega is small: deep in the money for spot, strike, rate,
dividend and maturity, and deep out of the money for the price. The implied volatility does not change when spot,
strike and price are multiplied by the same factor, hence

```math
S \, \partial_S \sigma + K \, \partial_K \sigma + V \, \partial_V \sigma = 0.
```

![Derivatives of the implied volatility of a call](assets/figures/impv_derivatives-light.svg)![Derivatives of the implied volatility of a call](assets/figures/impv_derivatives-dark.svg)

### Forward and reverse rules

Denoting by ``\nu = \partial_{\sigma}f`` the vega and by ``\theta`` the inputs other than the price, the tangent of the
implied volatility in forward mode is

```math
\dot{\sigma} = \frac{\dot{V} - \sum_{\theta} \partial_{\theta}f \, \dot{\theta}}{\nu},
```

while in reverse mode the adjoint ``\bar{\sigma}`` is propagated to the inputs as

```math
\bar{V} = \frac{\bar{\sigma}}{\nu}, \qquad \bar{\theta} = -\frac{\partial_{\theta}f}{\nu} \, \bar{\sigma}.
```

The partial derivatives ``\partial_{\theta}f`` and ``\nu`` are the closed form sensitivities of the Black formula,
evaluated once at the solution ``\sigma``: a gradient costs little more than the implied volatility itself (see
[Performance](performance.md)).

### Taylor series of any order

For a truncated Taylor series in the inputs (TaylorSeries.jl, TaylorDiff.jl), ``\sigma`` is the solution of
``f(\sigma) = V`` in the algebra of truncated series. Starting from ``\sigma_0``, the implied volatility of the constant
terms, Newton's method on the whole series

```math
\sigma_{m+1} = \sigma_m + \frac{V - f(\sigma_m)}{\partial_{\sigma}f(\sigma_m)}
```

is exact, not an approximation: the error of ``\sigma_0`` is ``O(t)`` and each step squares it, so after ``m`` steps it
is ``O(t^{2^m})``. Hence ``\lceil \log_2(n+1) \rceil`` steps give all the coefficients of a series of order ``n``.

Complex numbers, for the complex step method, are covered in
[Implied volatility](implied_volatility.md#Complex-numbers).
