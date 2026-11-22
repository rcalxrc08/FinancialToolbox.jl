# Stage 03: barrier options

_Facts the barrier pricers rely on._ (Layer 3 reference.)

- `blsdownout`, `blsupout(S0, K, r, T, σ, d, H, FlagIsCall = true)`: continuous monitoring, no rebate, by the
  reflection principle `V(S0) - (H/S0)^p V(H²/S0)`, over `blsprice` and `blsbin`; the knock-ins (`blsdownin`,
  `blsupin`) by in-out parity (#80, 0.8.1).
- No formula of their own and no differentiation rules: every backend differentiates through the code.
- Branch free: calls and puts differ by a 0/-1 weight from `call_put_sign`; the strike against the barrier is absorbed
  by `barrier_max`/`barrier_min` (`max`/`min`, complex numbers compared by `domain_value`, without promoting the real
  argument). Zygote: 55 μs with `if FlagIsCall`, 2.8 μs branch free (#80).
- References: QuantLib 1.32 `AnalyticBarrierEngine` values to 1e-13 (`QUANTLIB_BARRIER` in `test/setup.jl`); the
  derivative cases by central differences in BigFloat at the QuantLib points; a Brownian bridge Monte Carlo check in
  `docs/src/barriers.md`.
- They are the references of FinancialMonteCarlo's barrier options; more analytical options are listed in #85.
