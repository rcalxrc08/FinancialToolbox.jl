# Stage 04: implied volatility

_Facts the implied volatility relies on._ (Layer 3 reference.)

- `blsimpv`/`blkimpv` reduce to `blimpv(F, K, T, price, …)`, which dispatches on `promote_type` of the inputs (a type,
  not a value) through `blimpv_impl`: real floats run the domain checks and Let's Be Rational, `Complex` runs Newton
  from the real solution (analytic continuation, for the complex step), and the extensions add methods for their number
  types.
- The derivatives never go through the solver: they come from the implicit function theorem (`blimpv_sensitivities`),
  in the ChainRules rules here and in every extension.
- The solver (Jäckel, *Let's Be Rational*, 2024 version): constants are `@irrational` (exact for `BigFloat`, no
  promotion for `Float32`); keep them so. `blimpv_lets_be_rational` promotes its inputs to a common type first (`sqrt`
  of an `Int` strike is a `Float64`), and solves `Float16` in `Float32` (some approximations return `Float64` for it,
  and `erfinv(::Float16)` was wrong before SpecialFunctions 2.9.2).
- `typed_literal` and `tau` in the solver are not traced by Zygote (the implied volatility has rules).
- References: round trips and accuracy grids in Float64 and Float32 against BigFloat; a reference dataset
  (`test/core/implied_volatility_dataset.json`).
- Open: #81 (share the forward-mode implied volatility of the extensions, `primal_value`), #84 (Bachelier price and
  implied normal volatility).
