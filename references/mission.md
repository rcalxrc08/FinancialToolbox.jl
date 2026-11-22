# Mission

_Why the package exists and how to tell whether it succeeds._ (Layer 3 reference: stable, changes only with a decision
in `decisions.md`.)

## Purpose

Closed-form Black and Black–Scholes prices, Greeks, barrier options, implied volatilities and day counts with the
Matlab Financial Toolbox syntax, usable as the analytic layer under Monte Carlo, Fourier and calibration packages:
every function generic in the number type, differentiable by every Julia AD backend, and runnable inside GPU kernels.

## Goals

- Matlab-compatible names and values (`blsprice`, `blsimpv`, `yearfrac`, …).
- Implied volatility to machine precision in every float type (Let's Be Rational), derivatives by the implicit
  function theorem.
- Every number type and AD backend gives the same derivatives (`DERIVATIVE_CASES`).
- Zero allocations on the scalar paths; works in CUDA kernels.

## Constraints

- Julia ≥ 1.10; registered in General (AutoMerge rules apply).
- No `Float64` constants; no branches on differentiated paths; no allocations in kernel-reachable code.
- Hard dependencies stay light (ChainRulesCore, SpecialFunctions, IrrationalConstants, MuladdMacro, Dates); backends
  are weak.

## Success criteria

- The suite passes on 1.10 and 1 (CI) and the CUDA suite locally; `core/element_types.jl` keeps Float32 in, Float32
  out.
- BenchmarkCI shows no regression on a PR.

## Non-goals

- Models other than Black/Black–Scholes (FinancialMonteCarlo, FinancialFFT); Bachelier is proposed in #84.
- Calibration (FinancialCalibrator); Monte Carlo (FinancialMonteCarlo).
- Discrete barrier monitoring and rebates.
