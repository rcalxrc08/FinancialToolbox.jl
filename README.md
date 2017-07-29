# FinancialModule
[![Build Status](https://travis-ci.org/rcalxrc08/FinancialModule.jl.svg?branch=master)](https://travis-ci.org/rcalxrc08/FinancialModule.jl)
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/147ulk4et2sim293?svg=true)](https://ci.appveyor.com/project/rcalxrc08/financialmodule-jl)
[![codecov](https://codecov.io/gh/rcalxrc08/FinancialModule.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rcalxrc08/FinancialModule.jl?branch=master)
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

Currently supports classical numerical input, and other less common like:

- Complex Numbers
- [Dual Numbers](https://github.com/JuliaDiff/DualNumbers.jl)
- [HyperDual Numbers](https://github.com/JuliaDiff/HyperDualNumbers.jl)

The module is standalone.

## How to Install
To install the package simply type on the Julia REPL the following:
```Julia
Pkg.clone("https://github.com/rcalxrc08/FinancialModule.jl.git")
```
## How to Test
After the installation, to test the package type on the Julia REPL the following:
```Julia
Pkg.test("FinancialModule")
```
## Example of Usage
The following example is the pricing of a European Call Option with underlying varying
according to the Black Scholes Model, given the implied volatility.
After that it is possible to check the result computing the inverse of the Black Scholes formula.
```Julia
#Import the Package
using FinancialModule

#Define input data
spot=10;K=10;r=0.02;T=2.0;sigma=0.2;d=0.01;

#Call the function
Price=blsprice(spot,K,r,T,sigma,d)
#Price=1.1912013169995816

#Check the Result
Volatility=blsimpv(spot,K,r,T,Price,d)
#Volatility=0.20000000000000007
```

### Contributors
Thanks to [Modesto Mas](https://github.com/mmas) for the implementation of the [Brent Method](http://blog.mmast.net/brent-julia). 
