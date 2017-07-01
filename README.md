# FinancialModule
[![Build Status](https://travis-ci.org/rcalxrc08/FinancialModule.jl.svg?branch=master)](https://travis-ci.org/rcalxrc08/FinancialModule.jl)
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/147ulk4et2sim293?svg=true)](https://ci.appveyor.com/project/rcalxrc08/financialmodule-jl)
[![codecov](https://codecov.io/gh/rcalxrc08/FinancialModule.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rcalxrc08/FinancialModule.jl?branch=master)
##### This is a Julia package containg some useful Financial function for Pricing and Risk Management for the Black and Scholes Model.

It currently contain the following functions:

- blsprice: Black & Scholes Price for European Options.
- blsdelta: Black & Scholes Delta sensitivities for European Options.
- blsgamma: Black & Scholes Gamma sensitivities for European Options.
- blstheta: Black & Scholes Theta sensitivities for European Options.
- blsvega: Black & Scholes Vega sensitivities for European Options.
- blsrho: Black & Scholes Rho sensitivities for European Options.
- blsimpv: Black & Scholes Implied Volatility for European Options (using [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl) package).

Currently supports classical numerical input, and other less common like:

- Complex Numbers
- [Dual Numbers](https://github.com/JuliaDiff/DualNumbers.jl)
- [HyperDual Numbers](https://github.com/JuliaDiff/HyperDualNumbers.jl)

The only dependency is the package [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl) in order to achieve the inversion of the
Black and Scholes Formula.