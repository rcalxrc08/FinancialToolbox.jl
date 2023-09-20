# FinancialToolbox
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rcalxrc08.github.io/FinancialToolbox.jl/dev)
[![Build Status](https://travis-ci.org/rcalxrc08/FinancialToolbox.jl.svg?branch=master)](https://travis-ci.org/rcalxrc08/FinancialToolbox.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/3udcsjb9si6plt3h/branch/master?svg=true)](https://ci.appveyor.com/project/rcalxrc08/financialtoolbox-jl/branch/master)
[![codecov](https://codecov.io/gh/rcalxrc08/FinancialToolbox.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rcalxrc08/FinancialToolbox.jl?branch=master)
##### This is a Julia package containing some useful Financial functions for Pricing and Risk Management under the Black and Scholes Model.
###### The syntax is the same of the Matlab Financial Toolbox.

```@contents
```

Currently supports classical numerical input and other less common like:

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
