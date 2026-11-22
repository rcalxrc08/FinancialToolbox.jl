# Stage 02: pricing

_Facts the prices and Greeks rely on._ (Layer 3 reference.)

- `normcdf`, `normpdf`, the pricers and the Greeks all reduce to `blprice_impl(F, K, T, σ, FlagIsCall)`, the
  undiscounted Black formula, which has ChainRules `frule`/`rrule` with closed-form partials
  (`blprice_and_sensitivities`).
- Domain checks: `blcheck(S0, K, T[, σ])` and `check_positive(x, message)`, argument by argument through
  `domain_value` (real part of a complex, constant term of a Taylor series, `nothing` for symbolic values: the
  extensions add methods). Reuse `check_positive` for new checks; messages are constant strings (GPU kernels).
- `check_positive`, `blcheck` and `call_put_sign` are non-differentiable for ChainRules (Zygote) and `@zero_adjoint`
  for Mooncake (it does not read ChainRules' `@non_differentiable`): differentiated, they made Zygote gradients type
  unstable and Mooncake's twice as slow. Enzyme finds them inactive by itself (an `inactive` rule measured no gain).
- Helpers: `call_put_sign` (±1), `square`, `cube` (`conventions.md`), `internal_sqrt` (wrapped per number type in the
  DualNumbers and HyperDualNumbers extensions), constants `one_internal`, `two_internal`, `minus_one_internal`,
  `minus_two_internal`.
- `(call_put_sign(c) - one_internal) ÷ two_internal` is minus the put indicator.
- Reference values: Matlab (`MATLAB` in `test/setup.jl`); the Greeks against `closed_form_greeks`.
