# Decisions

_Architecture decisions, oldest first. Append; a reversed decision gets a new entry that says "supersedes D-NNN"._
(Layer 3 reference.) Read before a refactor: a structure that looks accidental may be an entry here.

## D-001 Everything reduces to `blprice_impl`

- **Decision:** every price and Greek reduces to the undiscounted Black formula `blprice_impl(F, K, T, σ, FlagIsCall)`,
  which carries the closed-form `frule`/`rrule`.
- **Why:** one set of partials for every public function and backend.
- **Consequences:** `pricing.md`; a new closed form gets its partials there.
- **Status:** active

## D-002 Implied volatility derivatives by the implicit function theorem

- **Decision:** derivatives of `blimpv` never go through the solver: `blimpv_sensitivities` in every rule and extension.
- **Why:** the solver has branches and iterations; the implicit function theorem is exact and cheap.
- **Consequences:** `implied_volatility.md`, `autodiff.md`.
- **Status:** active

## D-003 (2026-11-07, 6c0b74e) Element types: Float32 in, Float32 out

- **Decision:** no `Float64` constants or buffers; `@irrational` constants; a test of the output type for every
  function, input position and number type.
- **Why:** type-stability checks did not catch a promotion to a well-defined wider type (#74).
- **Consequences:** `test/core/element_types.jl`; rule in `CLAUDE.md`.
- **Status:** active

## D-004 (2026-11-07) Broadcast rules through `value_and_partials`

- **Decision:** ChainRules rules for the broadcasts of `blsprice`, `blkprice`, `blsimpv`, `blkimpv` with one fused pass;
  ReverseDiff tape instructions written by hand on the same function.
- **Why:** Zygote reran a GPU broadcast once per argument with duals (5-8 times slower than the CPU); `ReverseDiff.@grad`
  gave wrong gradients from compiled tapes away from the recording point.
- **Consequences:** stage 05; `autodiff.md`.
- **Status:** active

## D-005 (2026-11-15, 90a53d4) Branch-free differentiable code, `muladd`, `square`/`cube`

- **Decision:** no `if` on flags or values in differentiable code; `muladd` for `a * b + c`; `square`/`cube` instead of
  powers.
- **Why:** Zygote ~20x slower on control flow (barrier gradient 55 μs vs 2.8 μs, #80; FluxML/Zygote.jl#1736, #1754);
  `x^2` 1.3-6x slower than the product on BigFloat and duals. Zygote 0.7.19 (2026-11-22) fixed #1754: re-measured in
  fresh processes, a ternary on a flag 18-21 → 2.8-2.9 μs against 3.2-3.4 μs for a select, two nested branches 30-43 →
  5.4-5.7 μs against 5.1-5.2 μs for `ifelse`. The Zygote reason for the rule is gone from 0.7.19 on; the rule is relaxed
  in D-009.
- **Consequences:** rules in `CLAUDE.md`, `conventions.md`.
- **Status:** active for `muladd` and `square`/`cube`; the branch-free part is superseded by D-009.

## D-006 (2026-11-15, 90a53d4; 0.8.1) Barrier options from `blsprice` and `blsbin`

- **Decision:** barriers by the reflection principle over existing pricers, no rules of their own.
- **Why:** every backend differentiates them through the code; one formula for calls and puts (#80).
- **Consequences:** `barriers.md`.
- **Status:** active

## D-007 (2026-11-18, 7da0fd5) Rely on TaylorDiff's own `erfc`

- **Decision:** drop the own `normcdf(::TaylorScalar)`; compat floor TaylorDiff 0.3.6.
- **Why:** upstream fixed `erfc` (JuliaDiff/TaylorDiff.jl#113): exact, Float32, no allocation, runs in kernels, faster.
- **Consequences:** `autodiff.md`, `dependencies.md`.
- **Status:** active

## D-008 (2026-11-22) Layered context (ICM)

- **Decision:** the repository context follows the Interpretable Context Methodology: `CLAUDE.md` (L0), `CONTEXT.md`
  routing (L1), stage contracts (L2), `references/` (L3), `state/` (L4); `test/context.jl` keeps it in sync (#89).
- **Why:** the same layout worked in FinancialCalibrator and VibratoMonteCarlo; a single `CLAUDE.md` loads everything
  for every task and drifts.
- **Consequences:** every source file belongs to a stage folder and its contract.
- **Status:** active

## D-009 (2026-11-22) Branches allowed in differentiable code (supersedes the branch-free part of D-005)

- **Decision:** `if` and ternaries on flags or values are allowed in differentiable code; selects (`call_put_sign`
  weights, `max`/`min`) remain where they make one formula, and in GPU kernels; a sign weight rather than `ifelse` on a
  scalar flag.
- **Why:** Zygote 0.7.19 fixed the `Vector{Any}` stacks of branch-only code (FluxML/Zygote.jl#1754): re-measured, a
  ternary on a flag 18-21 → 2.8-2.9 μs against 3.2-3.4 μs for a sign weight, nested branches as fast as nested `ifelse`;
  `ifelse` on a scalar flag stays ~4x a sign weight. Mooncake and Enzyme never cared.
- **Consequences:** the tests require Zygote 0.7.19; rule in `CLAUDE.md`, `conventions.md`.
- **Status:** active
