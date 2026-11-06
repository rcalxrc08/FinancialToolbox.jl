```@raw html
<img class="pkg-hero-logo" src="assets/logo.png" alt="FinancialToolbox.jl logo" width="96" height="96">
```

# FinancialToolbox.jl

```@raw html
<p class="pkg-roles"><b>Black &amp; Scholes</b> · <b>Greeks</b> · <b>Implied volatility</b></p>
<div class="pkg-intro">
<p>Pricing, Greeks and implied volatility under the Black and the Black and Scholes models, with the same syntax as the
Matlab Financial Toolbox. Generic in the number type: it works with <code>Float32</code>, <code>BigFloat</code>,
complex numbers and automatic differentiation out of the box.</p>
</div>
<nav class="pkg-links">
<a class="pkg-btn" href="https://github.com/rcalxrc08/FinancialToolbox.jl"><svg viewBox="0 0 16 16" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/></svg> GitHub</a>
<a class="pkg-btn" href="https://github.com/rcalxrc08/FinancialToolbox.jl/stargazers">★ Star</a>
<a class="pkg-btn" href="#Quick-start">Get started ↓</a>
<a class="pkg-btn" href="https://rcalxrc08.github.io/">All projects</a>
</nav>
```

## Features

- **Pricing**: [`blsprice`](@ref), [`blkprice`](@ref) (European options in the Black and Scholes and Black models),
  [`blsbin`](@ref) (binary options), see [Pricing and Greeks](pricing.md).
- **Sensitivities**: [`blsdelta`](@ref), [`blsgamma`](@ref), [`blstheta`](@ref), [`blsvega`](@ref),
  [`blsrho`](@ref), [`blslambda`](@ref), [`blspsi`](@ref), [`blsvanna`](@ref).
- **Implied volatility**: [`blsimpv`](@ref), [`blkimpv`](@ref), based on the 2024 version of Peter Jäckel's
  [Let's Be Rational](http://www.jaeckel.org/LetsBeRational.pdf): at most two Householder iterations, accurate to the
  attainable machine precision for any moneyness, see [Implied volatility](implied_volatility.md).
- **Dates**: [`yearfrac`](@ref), [`daysact`](@ref), [`fromExcelNumberToDate`](@ref), see [Dates](dates.md).

Every function is generic in the number type:

- `Float64`, `Float32` (computed in single precision), `BigFloat` (computed in full precision, implied volatility
  included) and complex numbers (the implied volatility returns the analytic continuation of the real one).
- Automatic differentiation, forward and reverse, first and higher order, see [Automatic differentiation](ad.md):
  [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl), [ReverseDiff.jl](https://github.com/JuliaDiff/ReverseDiff.jl),
  [Zygote.jl](https://github.com/FluxML/Zygote.jl), [Mooncake.jl](https://github.com/chalk-lab/Mooncake.jl),
  [Enzyme.jl](https://github.com/EnzymeAD/Enzyme.jl), [TaylorSeries.jl](https://github.com/JuliaDiff/TaylorSeries.jl),
  [TaylorDiff.jl](https://github.com/JuliaDiff/TaylorDiff.jl), [DualNumbers.jl](https://github.com/JuliaDiff/DualNumbers.jl),
  [HyperDualNumbers.jl](https://github.com/JuliaDiff/HyperDualNumbers.jl).
- Symbolic computations with [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl).

## Installation

```julia
using Pkg
Pkg.add("FinancialToolbox")
```

## Quick start

The price of a European call in the Black and Scholes model, and back to the volatility:

```@example quickstart
using FinancialToolbox
S0 = 100.0; K = 100.0; r = 0.02; T = 1.2; σ = 0.2; d = 0.01
price = blsprice(S0, K, r, T, σ, d)
```

```@example quickstart
blsimpv(S0, K, r, T, price, d)
```

The last argument selects a put, and the Greeks take the same arguments:

```@example quickstart
blsprice(S0, K, r, T, σ, d, false), blsdelta(S0, K, r, T, σ, d, false), blsvega(S0, K, r, T, σ, d)
```

The same functions in single and in arbitrary precision:

```@example quickstart
blsimpv(Float32.((S0, K, r, T, price, d))...), blsimpv(big.((S0, K, r, T, price, d))...)
```

## Contents

```@contents
Pages = ["pricing.md", "implied_volatility.md", "ad.md", "performance.md", "dates.md", "api.md"]
Depth = 2
```
