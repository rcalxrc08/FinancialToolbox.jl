# Benchmarks

The BenchmarkCI suite (CI compares a pull request with master, a push with the previous commit) and the GPU table.

## Inputs

| Load | Why |
|:--|:--|
| `benchmarks.jl` | the suite: scalar calls in Float64, Float32, Float16, DualNumbers; Zygote, Mooncake and ReverseDiff gradients of `blsprice`, `blsvega`, `blsimpv`, `blsdownout`; a smile of 1000 options |
| `environment.jl` | the environment the scripts activate |
| `run.jl` | runs the suite with `tune.json` and prints the summary |
| `tune.jl` | retunes `tune.json` |
| `summary.jl` | the summary table |
| `gpu/run.jl` | the GPU vs CPU table of `docs/src/gpu.md` |
| `references/performance.md` | how to measure, traps |

## Process

- After adding or renaming a benchmark, rerun `tune.jl` on an idle machine and commit `tune.json`.
- Zygote benchmarks: interpolated non-constant arguments, no `$(args)...` splat (`references/performance.md`).
- A change to a hot path is timed before and after (old commit in a `git worktree`, fresh processes).

## Outputs

The BenchmarkCI comment; the GPU table in `docs/src/gpu.md`.
