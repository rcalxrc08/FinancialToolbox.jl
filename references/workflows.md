# Workflows: commands, Kaimon, CI, releases

_How to run, test, document and release._ (Layer 3 reference.)

## Kaimon session

- `start_session(project_path = "C:/Users/Nicola/.julia/dev/FinancialToolbox")`; `kaimon.toml` pins Julia 1.13.
- First call: `ex(q = false, e = "(VERSION, Base.active_project(), pathof(FinancialToolbox))")`.
- The number types and AD backends are test dependencies: check them through `run_tests()`.
- Do not run `julia --project` scripts that precompile this package while the session is open (Revise keeps the old
  code); restart the session afterwards.

## Commands

```bash
julia --project -e 'import Pkg; Pkg.test()'      # test/runtests.jl: every file of TEST_FILES, prints the time of each
julia --project=test -e 'include("test/core/element_types.jl")'   # a single test file
julia --project=test/cuda -e 'import Pkg; Pkg.instantiate(); include("test/cuda/runtests.jl")'  # needs an NVIDIA GPU
julia --project=test/reactant -e 'import Pkg; Pkg.instantiate(); include("test/reactant/runtests.jl")'  # Reactant (XLA), minutes to precompile; REACTANT_BACKEND=cuda on Linux
julia benchmark/run.jl                           # benchmark suite (BenchmarkCI runs it on CI); benchmark/tune.jl retunes tune.json
julia --project=benchmark/gpu -e 'import Pkg; Pkg.instantiate(); include("benchmark/gpu/run.jl")'  # GPU vs CPU table of docs/src/gpu.md
julia --project=docs docs/make.jl                # Documenter site, into docs/build
julia -e 'using JuliaFormatter; format(".")'     # .JuliaFormatter.toml
```

## CI

`CI.yml`: Julia 1.10 (the compat floor since 0.8.1) and 1, coverage on Codecov (100% before the GPU work). BenchmarkCI
(`benchmark.yml`). `DeployPage.yml`: docs with GitHub Pages from Actions (no `gh-pages` branch). CompatHelper,
dependabot, TagBot. CI has no GPU. Default branch `master`.

## Sub-environments

`test/`, `test/cuda/`, `test/reactant/`, `docs/` and `benchmark/gpu/` load the package through `[sources]` with a path; each has a
`[compat]` entry for the package itself, so CompatHelper does not open PRs to add one. Bump these entries in the same
commit as a breaking version bump, otherwise the environment fails to resolve.

## Release

Bump `version` in `Project.toml`, push to `master`, wait for CI, then comment `@JuliaRegistrator register` on the
commit. TagBot creates the tag and the release; if it opens a "manual intervention" issue, create the release at the
registered commit with `gh release create vX.Y.Z --target <full sha> --latest=false` (for an old version).
