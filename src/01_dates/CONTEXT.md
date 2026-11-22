# Stage 01: dates

Matlab-style day counts.

## Inputs

| Load | Why |
|:--|:--|
| `dates.jl` | `yearfrac` (Matlab bases 0-7), `daysact`, `fromExcelNumberToDate`, one small function per 30/360 convention |
| `references/dates.md` | the conventions, the integer arithmetic, the equal-dates rule |
| `references/conventions.md` | before adding a function |

## Process

- Day counts in integer arithmetic, one division at the end.
- One small function per 30/360 convention: they differ only by the adjustment of the days.
- Equal dates return 0 before any convention (30/360 PSA would not).

## Outputs

`yearfrac`, `daysact`, `fromExcelNumberToDate`. Checked by `test/core/dates.jl` (Matlab values).

## Verify (Kaimon)

Setup: `using FinancialToolbox, Dates`.

| Check | Expect |
|:--|:--|
| `yearfrac(Date(2020, 1, 1), Date(2020, 1, 1), 1)` | `0` (or `0.0`) |
| `@inferred yearfrac(Date(2020, 1, 1), Date(2021, 1, 1), 0)` | a float, no error |
