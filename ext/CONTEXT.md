# Extensions

One extension per AD backend or number type; the package loads and works without any of them.

## Inputs

| Load | Why |
|:--|:--|
| `FinancialToolboxForwardDiffExt.jl` | implied volatility on `Dual`s: solve on the values, add `(price - blprice(σ)) / vega` |
| `FinancialToolboxDualNumbersExt.jl` | the same, plus `normcdf` and `internal_sqrt` of a `Dual` (its `erfc` and `sqrt` promote to Float64) |
| `FinancialToolboxHyperDualNumbersExt.jl` | the same, plus `normcdf` and `internal_sqrt` |
| `FinancialToolboxMooncakeExt.jl` | `@from_chainrules` for the closed-form rules, `@zero_adjoint` for the checks; `Nfwd.NDual` (Mooncake inside GPU broadcasts) implied volatility |
| `FinancialToolboxEnzymeCoreExt.jl` | `forward`/`augmented_primal`/`reverse` rules for `blimpv` |
| `FinancialToolboxReverseDiffExt.jl` | `blsprice`, `blkprice`, `blsimpv`, `blkimpv` as single hand-written tape instructions with `value_and_partials` |
| `FinancialToolboxTaylorSeriesExt.jl` | `erfc` of a series (coefficient recurrence, coefficients in the input's `JetSpace`), Newton on the series for the implied volatility, `square(::TaylorN)` |
| `FinancialToolboxTaylorDiffExt.jl` | implied volatility by Newton on the series (TaylorDiff's own `erfc` is exact since 0.3.6) |
| `FinancialToolboxReactantExt.jl` | `domain_value(::TracedRNumber)` (`nothing`: no check, a branch on a traced value does not compile); prices, Greeks and their Enzyme derivatives compile with Reactant, `blsimpv` not yet (#92) |
| `FinancialToolboxSymbolicsExt.jl` | `domain_value(::Num)` (`nothing`: no check), `blimpv` registered as a symbolic function with its derivative |
| `references/autodiff.md` | what each backend needs and why |
| `references/dependencies.md` | compat floors, upstream workarounds |

## Process

- An extension adds methods (`domain_value`, `blimpv_impl`, rules); it never changes the meaning of a package method.
- Derivatives of the implied volatility come from `blimpv_sensitivities` (implicit function theorem), never the solver.
- No `ReverseDiff.@grad`: it keeps the pullback of the recording point, so compiled tapes are wrong elsewhere.
- Upstream workarounds are listed in `references/dependencies.md` with the issue and version.

## Outputs

`Base.get_extension(FinancialToolbox, :FinancialToolbox<Dep>Ext) !== nothing` after `using <Dep>`. Checked by
`test/numbers/*.jl`, `test/ad/*.jl`, `test/cuda/ad_suite.jl`, `test/reactant/runtests.jl` (local only).

## Verify (Kaimon)

| Check | Expect |
|:--|:--|
| `run_tests()` | `numbers/` and `ad/` files pass |
