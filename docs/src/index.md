# FinancialToolbox
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rcalxrc08.github.io/FinancialToolbox.jl/dev)
[![Build Status](https://travis-ci.org/rcalxrc08/FinancialToolbox.jl.svg?branch=master)](https://travis-ci.org/rcalxrc08/FinancialToolbox.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/3udcsjb9si6plt3h/branch/master?svg=true)](https://ci.appveyor.com/project/rcalxrc08/financialtoolbox-jl/branch/master)
[![codecov](https://codecov.io/gh/rcalxrc08/FinancialToolbox.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rcalxrc08/FinancialToolbox.jl?branch=master)
##### This is a Julia package containing some useful Financial functions for Pricing and Risk Management under the Black and Scholes Model.
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

Currently supports classical numerical input and other less common like:

- Complex Numbers
- [Dual Numbers](https://github.com/JuliaDiff/DualNumbers.jl)
- [HyperDual Numbers](https://github.com/JuliaDiff/HyperDualNumbers.jl)

It also contains some functions that could be useful for the Dates Management:

- yearfrac : fraction of years between two Dates (currently only the first seven convention of Matlab are supported).
- daysact  : number of days between two Dates.

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

### Contributors
Thanks to [Modesto Mas](https://github.com/mmas) for the implementation of the [Brent Method](http://blog.mmast.net/brent-julia). 
