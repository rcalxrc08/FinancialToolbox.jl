# FinancialToolbox <img src="etc/logo.png" width="40">  
[![status](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rcalxrc08.github.io/FinancialToolbox.jl/)
[![CI](https://github.com/rcalxrc08/FinancialToolbox.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/rcalxrc08/FinancialToolbox.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/rcalxrc08/FinancialToolbox.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rcalxrc08/FinancialToolbox.jl?branch=master)
##### This is a Julia package containing some useful Financial functions for Pricing and Risk Management under the Black and Scholes Model.
###### The syntax is the same of the Matlab Financial Toolbox.
It currently contains the following functions:

- blsprice : Black & Scholes Price for European Options.
- blsbin   : Black & Scholes Price for Binary European Options.
- blkprice : Black Price for European Options.
- blsdelta : Black & Scholes Delta sensitivity for European Options.
- blsgamma : Black & Scholes Gamma sensitivity for European Options.
- blstheta : Black & Scholes Theta sensitivity for European Options.
- blsvega  : Black & Scholes Vega sensitivity for European Options.
- blsrho   : Black & Scholes Rho sensitivity for European Options.
- blslambda: Black & Scholes Lambda sensitivity for European Options.
- blspsi   : Black & Scholes Psi sensitivity for European Options.
- blsvanna : Black & Scholes Vanna sensitivity for European Options.
- blsimpv  : Black & Scholes Implied Volatility for European Options.
- blkimpv  : Black Implied Volatility for European Options.

The implied volatility is computed with the 2024 version of Peter Jäckel's [Let's Be Rational](http://www.jaeckel.org/LetsBeRational.pdf):
at most two Householder iterations, accurate to the attainable machine precision for any moneyness, maturity and volatility.

It also contains some functions that could be useful for the Dates Management:

- yearfrac : fraction of years between two Dates (currently only the first seven convention of Matlab are supported).
- daysact  : number of days between two Dates.
- fromExcelNumberToDate : conversion of an Excel serial number to a Date.

## Supported number types and automatic differentiation
Every function is generic in the number type:

- `Float64`, `Float32` (computed in single precision) and `BigFloat` (computed in full precision, implied volatility included).
- Complex Numbers: the implied volatility returns the analytic continuation of the real one, as needed by the complex step method.
- Automatic differentiation, forward and reverse mode, first and higher order:
  [ForwardDiff](https://github.com/JuliaDiff/ForwardDiff.jl), [ReverseDiff](https://github.com/JuliaDiff/ReverseDiff.jl), [Zygote](https://github.com/FluxML/Zygote.jl),
  [Mooncake](https://github.com/chalk-lab/Mooncake.jl), [Enzyme](https://github.com/EnzymeAD/Enzyme.jl),
  [TaylorSeries](https://github.com/JuliaDiff/TaylorSeries.jl), [TaylorDiff](https://github.com/JuliaDiff/TaylorDiff.jl),
  [Dual Numbers](https://github.com/JuliaDiff/DualNumbers.jl), [HyperDual Numbers](https://github.com/JuliaDiff/HyperDualNumbers.jl).
- Symbolic computations with [Symbolics](https://github.com/JuliaSymbolics/Symbolics.jl).

The implied volatility is never differentiated through the numerical solver: its derivatives are defined analytically via the
implicit function theorem, $\partial_\theta \sigma = -\partial_\theta f / \partial_\sigma f$ where $f$ is the Black and Scholes price
(ChainRulesCore `frule`/`rrule` and native rules for Enzyme, ForwardDiff and the Taylor series packages, see the [landing page](https://rcalxrc08.github.io/FinancialToolbox.jl/#AD)).

## Performance
Time to compute the price and the implied volatility, and their gradients with respect to all the inputs
with a forward (TaylorSeries, order one `TaylorN` in the six inputs) and a reverse (Mooncake) mode AD library:

| Function | Value (Float64) | Gradient, TaylorSeries (TaylorN) | Gradient, Mooncake (reverse mode) |
|:--|--:|--:|--:|
| `blsprice(S0, K, r, T, σ, d)` | 147 ns | 12.30 μs (83.5×) | 536 ns (3.6×) |
| `blsimpv(S0, K, r, T, price, d)` | 501 ns | 19.30 μs (38.6×) | 833 ns (1.7×) |

Julia 1.13.1, Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz, FinancialToolbox 0.7.1; minimum time over the BenchmarkTools samples,
in brackets the ratio to the value. The [landing page](https://rcalxrc08.github.io/FinancialToolbox.jl/#Performance) shows the same table
measured on the latest version of the package.

## How to Install
To install the package simply type on the Julia REPL the following:
```Julia
Pkg.add("FinancialToolbox")
```
## How to Test
After the installation, to test the package type on the Julia REPL the following:
```Julia
Pkg.test("FinancialToolbox")
```
## Example of Usage
The following example is the pricing of a European Call Option with underlying varying
according to the Black Scholes Model, given the implied volatility.
After that it is possible to check the result computing the inverse of the Black Scholes formula.
```Julia
#Import the Package
using FinancialToolbox

#Define input data
spot=10;K=10;r=0.02;T=2.0;σ=0.2;d=0.01;

#Call the function
Price=blsprice(spot,K,r,T,σ,d)
#Price=1.1912013169995816

#Check the Result
Volatility=blsimpv(spot,K,r,T,Price,d)
#Volatility=0.20000000000000002
```
The gradient of the implied volatility with respect to all the inputs, for instance with Mooncake:
```Julia
using FinancialToolbox, Mooncake

spot = 10.0; K = 10.0; r = 0.02; T = 2.0; d = 0.01; price = 1.1912013169995816
f(spot, K, r, T, price, d) = blsimpv(spot, K, r, T, price, d)
cache = Mooncake.prepare_gradient_cache(f, spot, K, r, T, price, d)
σ, (_, dspot, dK, dr, dT, dprice, dd) = Mooncake.value_and_gradient!!(cache, f, spot, K, r, T, price, d)
```
