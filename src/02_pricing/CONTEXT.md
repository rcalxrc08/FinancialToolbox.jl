# Stage 02: pricing

`normcdf`, `normpdf`, the Black and Black–Scholes prices and Greeks, the shared helpers and the domain checks.

## Inputs

| Load | Why |
|:--|:--|
| `financial.jl` | `blprice_impl` (undiscounted Black) with its `frule`/`rrule` (`blprice_and_sensitivities`), the public pricers and Greeks, `blcheck`, `check_positive`, `domain_value`, `call_put_sign`, `square`, `cube`, `internal_sqrt` |
| `references/pricing.md` | the reduction to `blprice_impl`, the domain checks, the helpers |
| `references/conventions.md` | number types, no branches, `muladd`, `square`/`cube` |
| `references/autodiff.md` | why the checks are non-differentiable and `@zero_adjoint` |

## Process

- Every price and Greek reduces to `blprice_impl(F, K, T, σ, FlagIsCall)`; a new closed form gets its partials there,
  not a rule per public function.
- Domain checks go argument by argument through `domain_value` (extensions add methods); reuse `check_positive`,
  messages are constant strings (GPU kernels).
- `check_positive`, `blcheck` and `call_put_sign` stay non-differentiable for ChainRules and `@zero_adjoint` for
  Mooncake.
- A new exported function: docstring with all its arguments, a row in `DERIVATIVE_CASES` (`test/setup.jl`), a line in
  `references/public_api.md`, a test in `test/core/element_types.jl`.

## Outputs

The exported pricers and Greeks. Checked by `test/core/pricing.jl` (Matlab values, BigFloat/Float32/Float16, input
validation), `test/core/element_types.jl`, and every number-type and AD test through `DERIVATIVE_CASES`.

## Verify (Kaimon)

Setup: `using FinancialToolbox, Test`.

| Check | Expect |
|:--|:--|
| `blsprice(10.0, 10.0, 0.02, 2.0, 0.2, 0.01)` (`REFERENCE` of `test/setup.jl`) | `1.191201316999582` (`MATLAB.call.price`) to ~1e-15 |
| `@inferred blsprice(10f0, 10f0, 0.02f0, 2f0, 0.2f0, 0.01f0)` | `Float32` |
| `@allocated blsprice(10.0, 10.0, 0.02, 2.0, 0.2, 0.01)` after warm-up, inside a function | `0` |
