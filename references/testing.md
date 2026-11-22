# Testing

_Reference values, their sources, the layout rules._ (Layer 3 reference.)

- Number types and AD backends check against the same references: `DERIVATIVE_CASES` in `test/setup.jl` (value,
  gradient with respect to every real input and gamma; `blsprice` from its closed-form Greeks, the barrier options at
  the QuantLib points by central differences in BigFloat, independent of any AD rule), through
  `test_derivative_cases(gradient; gamma)`. A new pricing function is a new row there, not a new check in every file.
- `test/runtests.jl` runs every file of `TEST_FILES` (a new file must be added there) in a module of its own, from the
  file's directory, inside a testset. Each file includes `test/setup.jl` (Test, FinancialToolbox, `REFERENCE`, `MATLAB`,
  `closed_form_greeks`), so it also runs alone.

| Values | Source |
|:--|:--|
| prices, Greeks, dates | Matlab Financial Toolbox (`MATLAB`) |
| barrier options | QuantLib 1.32 `AnalyticBarrierEngine` (`QUANTLIB_BARRIER`), to 1e-13 |
| implied volatility | round trips; BigFloat grids; a reference dataset (`core/implied_volatility_dataset.json`) |
| derivatives | closed-form Greeks; BigFloat central differences |

- Keep the tests lean: a property checked once per code path, not once per number type (input validation is generic
  code, the Greeks are checked against Matlab once, the number types against `DERIVATIVE_CASES`).
- Coverage: code reached only on GPUs (Mooncake's `NDual`) or by compiled tapes needs a CPU test that calls it directly.
- `ad/reversediff.jl` evaluates compiled tapes away from the recording point: the only test of the forward pass of the
  hand-written instructions.
- Enzyme gets the closure of each case through a function barrier (`enzyme_gradient` in `ad/enzyme.jl`).
- `test/oneapi/` is untracked (local experiment).
