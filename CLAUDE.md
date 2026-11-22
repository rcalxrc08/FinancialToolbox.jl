# CLAUDE.md

**FinancialToolbox.jl** prices European and barrier options under the Black and Black & Scholes models, with the
Greeks, the implied volatility (Peter Jäckel's *Let's Be Rational*, 2024 version) and Matlab-style day counts, with the
syntax of the Matlab Financial Toolbox (`blsprice`, `blsimpv`, `yearfrac`, …). Everything is generic in the number type:
`Float16`, `Float32`, `Float64`, `BigFloat`, complex numbers (complex step), every AD backend in `ext/`, and GPU arrays.
Registered in General; FinancialFFT, FinancialMonteCarlo, VibratoMonteCarlo and FinancialCalibrator depend on it.
Goals and non-goals: `references/mission.md`; why things are the way they are: `references/decisions.md`.

This workspace follows the Interpretable Context Methodology (layered context, arXiv:2603.16021): load only what the
task needs.

| Layer | Where | What |
|:--|:--|:--|
| 0 | this file | identity, map, rules that hold everywhere |
| 1 | `CONTEXT.md` | which stage or folder a task belongs to, shared references |
| 2 | `src/0N_*/CONTEXT.md`, `ext/`, `test/`, `docs/`, `benchmark/`, `etc/` | a contract per stage: inputs, process, outputs, runtime checks |
| 3 | `references/*.md` | stable facts, decisions and measurements, loaded when a contract lists them |
| 4 | `state/STATUS.md` | what is in flight: current focus, open issues, known problems |

Startup: read `state/STATUS.md`, then route the task through `CONTEXT.md`. Runtime truth comes from a Kaimon session
for this project (`kaimon.toml` pins the Julia); each contract's Verify table lists the checks to run after a change.

Map: `src/FinancialToolbox.jl` includes the stages in order, `01_dates` → `02_pricing` → `03_barriers` →
`04_implied_volatility` → `05_value_and_partials`; `ext/` one extension per AD backend or number type; `test/` the suite
(`test/cuda/` local GPU tests); `docs/` the Documenter site; `benchmark/` the BenchmarkCI suite and the GPU table.

Rules for every change (details in `references/conventions.md`):

- No `Float64` constants or buffers in generic code (`@irrational`, integer literals, `one`/`zero`); Float32 in,
  Float32 out.
- No `if` on flags or values in differentiable code (`call_put_sign`, weights, `max`/`min`); domain checks through
  `check_positive`/`blcheck`, non-differentiable, with constant messages.
- Code reachable from GPU kernels does not allocate nor index element by element (check `@allocated` on Julia 1.10).
- `@muladd`/`muladd` for every `a * b + c`, never negating an `Irrational` inside it; `square`/`cube`, never `x^2`/`x^3`.
- Reuse the author's packages and established libraries; every exported function documents all its arguments.
- Format with `.JuliaFormatter.toml`; update the CONTEXT.md, references and `state/STATUS.md` a change touches in the
  same commit (a new rule also gets an entry in `references/decisions.md`); default branch `master`; push to `origin`.
