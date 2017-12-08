# FinancialToolbox
[![Build Status](https://travis-ci.org/rcalxrc08/FinancialToolbox.jl.svg?branch=master)](https://travis-ci.org/rcalxrc08/FinancialToolbox.jl)
[![FinancialToolbox](http://pkg.julialang.org/badges/FinancialToolbox_0.5.svg)](http://pkg.julialang.org/detail/FinancialToolbox)
[![FinancialToolbox](http://pkg.julialang.org/badges/FinancialToolbox_0.6.svg)](http://pkg.julialang.org/detail/FinancialToolbox)
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/147ulk4et2sim293?svg=true)](https://ci.appveyor.com/project/rcalxrc08/FinancialToolbox-jl)
[![codecov](https://codecov.io/gh/rcalxrc08/FinancialToolbox.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rcalxrc08/FinancialToolbox.jl?branch=master)
##### This is a Julia package containing some useful Financial function for Pricing and Risk Management under the Black and Scholes Model.
###### The syntax is the same of the Matlab Financial Toolbox.
It currently contains the following functions:

- blsprice : Black & Scholes Price for European Options.
- blkprice : Black Price for European Options.
- blsdelta : Black & Scholes Delta sensitivity for European Options.
- blsgamma : Black & Scholes Gamma sensitivity for European Options.
- blstheta : Black & Scholes Theta sensitivity for European Options.
- blsvega  : Black & Scholes Vega sensitivity for European Options.
- blsrho   : Black & Scholes Rho sensitivity for European Options.
- blslambda: Black & Scholes Lambda sensitivity for European Options.
- blspsi   : Black & Scholes Psi sensitivity for European Options.
- blsvanna : Black & Scholes Vanna sensitivity for European Options.
- blsimpv  : Black & Scholes Implied Volatility for European Options (using [Brent Method](http://blog.mmast.net/brent-julia)).
- blkimpv  : Black Implied Volatility for European Options (using [Brent Method](http://blog.mmast.net/brent-julia)).

It also contains some functions that could be useful for the Dates Management:

- yearfrac : fraction of years between two Dates (currently only the first seven convention of Matlab are supported).
- daysact  : number of days between two Dates.
Currently supports classical numerical input, and other less common like:

- Complex Numbers
- [Dual Numbers](https://github.com/JuliaDiff/DualNumbers.jl)
- [HyperDual Numbers](https://github.com/JuliaDiff/HyperDualNumbers.jl)

The module is standalone.

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

### Contributors
Thanks to [Modesto Mas](https://github.com/mmas) for the implementation of the [Brent Method](http://blog.mmast.net/brent-julia). 
