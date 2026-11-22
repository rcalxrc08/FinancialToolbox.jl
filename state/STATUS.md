# Status

_What is in flight. Layer 4: volatile, rewritten freely; GitHub issues are the source of truth for tasks, this file is
the index an agent reads first._ Updated: 2026-11-22

## Current focus

Layered context (#89) on branch `context-layers`: done when `test/context.jl` and the full suite are green and the
branch is merged. Last release 0.8.1 (2026-11-18, barrier options #80).

## Active work

| Item | Branch | Issue | Next step |
|:--|:--|:--|:--|
| Layered context | `context-layers` | #89 | review, merge, push |

## Known issues

| Issue | Symptom | Workaround |
|:--|:--|:--|
| EnzymeAD/Enzyme.jl#3962 | Enzyme custom rules miss CUDA device overrides: `blsimpv` not differentiable with Enzyme in kernels | `@test_broken` in `test/cuda/ad_suite.jl` |
| JuliaDiff/ForwardDiff.jl#759 | ForwardDiff `gradient`/`jacobian` on GPU arrays | broadcast `ForwardDiff.derivative` |

## Enhancements

- #85 other options with analytical prices under Black–Scholes (references for FinancialMonteCarlo).
- #84 Bachelier price and implied normal volatility.
- #81 share the forward-mode implied volatility of the extensions (`primal_value`).

## Working notes

- `NOTES_2026-11-15.md` (untracked, repo root) is the session note of #80; that work was pushed and released in 0.8.1,
  so the note is stale and can be deleted. `etc/new_logo.jl` and `test/oneapi/` are untracked experiments.

Notes of an active initiative live next to this file as `state/YYYY-MM-DD-<topic>.md`. When the initiative ends, move
what stays true into `references/` or `references/decisions.md` and delete the note.
