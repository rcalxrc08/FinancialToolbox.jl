# Stage 04: implied volatility

`blsimpv`/`blkimpv`: Let's Be Rational for real floats, Newton for complex numbers and series, the derivatives by the
implicit function theorem.

## Inputs

| Load | Why |
|:--|:--|
| `financial_implied_volatility.jl` | `blsimpv`, `blkimpv` → `blimpv` → `blimpv_impl` (dispatch on the promoted type), `blimpv_sensitivities`, the `frule`/`rrule`, `blimpv_series_newton` |
| `financial_lets_be_rational.jl` | the solver (Jäckel 2024): `blimpv_lets_be_rational` (promotion, Float16 in Float32), `@irrational` constants |
| `financial_lets_be_rational_coefficients.jl` | the rational approximation coefficients of the solver |
| `references/implied_volatility.md` | dispatch, the promotion rules, the derivatives, Float16 |
| `references/autodiff.md` | the rules of every backend reuse `blimpv_sensitivities` |
| `references/conventions.md` | `@irrational` constants, no Float64 |

## Process

- The derivatives never go through the solver: implicit function theorem (`blimpv_sensitivities`), here and in every
  extension.
- `blimpv_impl` dispatches on `promote_type` of the inputs (a type, not a value): real floats run the domain checks and
  the solver, `Complex` runs Newton from the real solution (analytic continuation), extensions add their number types.
- Solver constants stay `@irrational` (exact for `BigFloat`, no promotion for `Float32`).

## Outputs

`blsimpv`, `blkimpv`. Checked by `test/core/implied_volatility.jl` (round trips, accuracy grids in Float64 and Float32
against BigFloat), `test/core/implied_volatility_dataset.jl` (reference dataset), and the number-type and AD tests.

## Verify (Kaimon)

Setup: `using FinancialToolbox, Test`; `p = blsprice(100.0, 95.0, 0.01, 1.0, 0.25, 0.0)`.

| Check | Expect |
|:--|:--|
| `blsimpv(100.0, 95.0, 0.01, 1.0, p, 0.0)` | `0.25` to ~1e-15 |
| `@inferred blsimpv(100f0, 95f0, 0.01f0, 1f0, Float32(p), 0f0)` | `Float32` |
| `@allocated blsimpv(100.0, 95.0, 0.01, 1.0, p, 0.0)` after warm-up, inside a function | `0` |
