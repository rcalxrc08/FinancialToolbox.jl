# Stage 03: barrier options

Continuously monitored single-barrier options without rebate, by the reflection principle.

## Inputs

| Load | Why |
|:--|:--|
| `financial_barrier.jl` | `blsdownout`, `blsupout`, `blsdownin`, `blsupin`, `barrier_max`/`barrier_min`, `barrier_image_exponent` |
| `references/barriers.md` | the formula, the branch-free construction, the QuantLib references |
| `references/conventions.md` | no branches on flags or values |

## Process

- Built from `blsprice` and `blsbin`: no formula of their own, no differentiation rules (every backend differentiates
  through the code); knock-ins by in-out parity.
- Branch free: calls and puts differ by a 0/-1 weight from `call_put_sign`; the strike against the barrier through
  `barrier_max`/`barrier_min` (complex numbers compared by `domain_value`, without promoting the real argument).
- The Zygote gradient of `blsdownout` in BenchmarkCI guards against branches (55 μs with an `if`, 2.8 μs without).

## Outputs

The four barrier pricers, the references of FinancialMonteCarlo's barrier options. Checked by `test/core/barrier.jl`
(QuantLib 1.32 values to 1e-13, in-out parity, limits, validation) and `DERIVATIVE_CASES`.

## Verify (Kaimon)

Setup: `using FinancialToolbox`; `S0, K, r, T, σ, d, H = 100.0, 100.0, 0.05, 1.0, 0.2, 0.0, 90.0`.

| Check | Expect |
|:--|:--|
| `blsdownout(S0, K, r, T, σ, d, H) + blsdownin(S0, K, r, T, σ, d, H) ≈ blsprice(S0, K, r, T, σ, d)` | `true` |
| `@allocated blsdownout(S0, K, r, T, σ, d, H)` after warm-up, inside a function | `0` |
