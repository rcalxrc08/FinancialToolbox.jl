# Tests and CI

How the suite is organized, how to run a part of it, what CI runs.

## Inputs

| Load | Why |
|:--|:--|
| `runtests.jl` | `TEST_FILES`: each file runs in a module of its own, from its directory, in a testset, with its time |
| `setup.jl` | `REFERENCE`, `MATLAB`, `QUANTLIB_BARRIER`, `closed_form_greeks`, `DERIVATIVE_CASES`, `test_derivative_cases` |
| `core/pricing.jl` | Matlab values, BigFloat/Float32/Float16, input validation |
| `core/barrier.jl` | QuantLib 1.32 values, in-out parity, limits, validation |
| `core/implied_volatility.jl` | round trips, accuracy grids in Float64 and Float32 against BigFloat |
| `core/implied_volatility_dataset.jl` | reference dataset (`implied_volatility_dataset.json`, relative path) |
| `core/dates.jl` | Matlab values |
| `core/element_types.jl` | Float32 in, Float32 out, for every function, input position and number type (#74) |
| `numbers/complex.jl` | complex step |
| `numbers/dual_numbers.jl` | ForwardDiff, DualNumbers, HyperDualNumbers against the closed-form Greeks |
| `numbers/taylor_series.jl` | TaylorSeries |
| `numbers/taylor_diff.jl` | TaylorDiff |
| `numbers/symbolics.jl` | derivatives, not simplified |
| `ad/zygote.jl` | Zygote |
| `ad/broadcast_rules.jl` | the broadcast rules against ForwardDiff, every argument and broadcast shape |
| `ad/reversediff.jl` | compiled tapes away from the recording point |
| `ad/mooncake.jl` | Mooncake |
| `ad/enzyme.jl` | Enzyme, through the `enzyme_gradient` function barrier |
| `gpu/jlarrays.jl` | `gpu/gpu_suite.jl` on JLArrays (GPU code path without a GPU, on CI) |
| `gpu/gpu_suite.jl` | the GPU suite shared with CUDA |
| `cuda/runtests.jl` | the GPU suite on CUDA, locally only |
| `cuda/ad_suite.jl` | ForwardDiff, DualNumbers, Zygote, Mooncake, TaylorDiff, Enzyme in kernels |
| `reactant/runtests.jl` | prices, Greeks and Enzyme derivatives compiled by Reactant against plain Julia, locally only (`blsimpv` `@test_broken`, #92) |
| `aqua.jl` | Aqua |
| `context.jl` | the context layers follow the code |
| `references/testing.md` | the reference values and their sources, the layout rules |
| `references/workflows.md` | commands, CI matrix |

## Process

- A new pricing function is a new row of `DERIVATIVE_CASES`, not a new check in every file.
- A new test file is added to `TEST_FILES`; it includes `setup.jl` so it also runs alone.
- Keep the tests lean: a property checked once per code path, not once per number type.
- CI has no GPU: run `test/cuda/` locally before pushing any change to `src/` or `ext/`.
- Code reached only on GPUs or by compiled tapes needs a CPU test that calls it directly (coverage).

## Outputs

A green `Pkg.test()` (each file's time printed); `context.jl` green whenever a file is added, moved or renamed.

## Verify (Kaimon)

| Check | Expect |
|:--|:--|
| `run_tests()` summary | pass; reports the Julia of `kaimon.toml` |
| `include("test/context.jl")` | pass |
