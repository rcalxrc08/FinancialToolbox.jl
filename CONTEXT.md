# CONTEXT.md: task routing (Layer 1)

Find the task, open the contract it points to, and load only the inputs listed there.

| Task | Contract |
|:--|:--|
| Day counts: `yearfrac`, `daysact`, Excel dates | `src/01_dates/CONTEXT.md` |
| Black and Black–Scholes prices, Greeks, `normcdf`, domain checks, the closed-form rules of `blprice_impl` | `src/02_pricing/CONTEXT.md` |
| Barrier options (`blsdownout`, `blsupin`, …), new analytical options | `src/03_barriers/CONTEXT.md` |
| Implied volatility: `blsimpv`/`blkimpv`, Let's Be Rational, complex and series solvers, its rules | `src/04_implied_volatility/CONTEXT.md` |
| `value_and_partials`, the broadcast rules (Zygote on GPU arrays) | `src/05_value_and_partials/CONTEXT.md` |
| A number type or AD backend (ForwardDiff, Dual/HyperDual, Taylor, Symbolics, Mooncake, Enzyme, ReverseDiff) | `ext/CONTEXT.md` |
| Adding or running tests, `DERIVATIVE_CASES`, the CUDA tests | `test/CONTEXT.md` |
| Documentation pages, figures, the GPU calibration example | `docs/CONTEXT.md` |
| BenchmarkCI suite, retuning, the GPU table | `benchmark/CONTEXT.md` |
| The logo | `etc/CONTEXT.md` |
| Commands, CI, releases, sub-environments | `references/workflows.md` |
| What is being worked on, known issues | `state/STATUS.md` |
| Whether a change fits the package's goals; why a rule exists | `references/mission.md`, `references/decisions.md` |

Shared references (Layer 3), each loaded only when a contract lists it: `public_api.md`, `conventions.md`,
`autodiff.md`, `gpu.md`, `dependencies.md`, `workflows.md`, `testing.md`, `performance.md`, `docs_design.md`, and per
stage `dates.md`, `pricing.md`, `barriers.md`, `implied_volatility.md`.

The stages communicate through Julia functions: 02 reduces every price and Greek to `blprice_impl(F, K, T, σ, FlagIsCall)`;
03 builds barriers from `blsprice`/`blsbin`; 04 inverts `blprice_impl`; 05 returns values and closed-form partials of
02 and 04 for the broadcast rules and ReverseDiff.
