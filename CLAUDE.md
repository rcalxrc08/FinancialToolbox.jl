# CLAUDE.md

Guidance for working in this repository.

## What this is

`FinancialToolbox.jl` prices European options under the Black and Black & Scholes models, with the Greeks, the implied
volatility (Peter Jäckel's *Let's Be Rational*, 2024 version) and Matlab-style day counts, with the syntax of the
Matlab Financial Toolbox (`blsprice`, `blsimpv`, `yearfrac`, ...). Everything is generic in the number type: `Float16`,
`Float32`, `Float64`, `BigFloat`, complex numbers (complex step), every AD backend in [ext/](ext/), and GPU arrays.

Registered in General. FinancialFFT, FinancialMonteCarlo and VibratoMonteCarlo depend on it.

## Commands

```bash
julia --project -e 'import Pkg; Pkg.test()'      # test/runtests.jl: every file of TEST_FILES, prints the time of each
julia --project=test -e 'include("test/core/element_types.jl")'   # a single test file
julia --project=test/cuda -e 'import Pkg; Pkg.instantiate(); include("test/cuda/runtests.jl")'  # needs an NVIDIA GPU
julia benchmark/run.jl                           # benchmark suite (BenchmarkCI runs it on CI); benchmark/tune.jl retunes tune.json
julia --project=benchmark/gpu -e 'import Pkg; Pkg.instantiate(); include("benchmark/gpu/run.jl")'  # GPU vs CPU table of docs/src/gpu.md
julia --project=docs docs/make.jl                # Documenter site, into docs/build
julia -e 'using JuliaFormatter; format(".")'     # .JuliaFormatter.toml
```

CI tests Julia 1.10 and 1. The default branch is `master`. The docs are deployed by DeployPage.yml with GitHub Pages
from Actions (no gh-pages branch).

## Architecture

- [src/financial.jl](src/financial.jl): `normcdf`, `normpdf`, the pricers and the Greeks. All of them reduce to
  `blprice_impl(F, K, T, σ, FlagIsCall)`, the undiscounted Black formula, which has ChainRules `frule`/`rrule` with
  closed form partials (`blprice_and_sensitivities`).
- [src/financial_implied_volatility.jl](src/financial_implied_volatility.jl): `blsimpv`/`blkimpv` reduce to
  `blimpv(F, K, T, price, ...)`, which dispatches on `promote_type` of the inputs (a type, not a value) through `blimpv_impl`: real
  floats run the domain checks and Let's Be Rational, `Complex` runs Newton from the real solution (analytic
  continuation, for the complex step), and the extensions add methods for their number types. The derivatives of
  the implied volatility never go through the solver: they come from the implicit function theorem
  (`blimpv_sensitivities`), in the ChainRules rules here and in every extension.
- [src/financial_lets_be_rational.jl](src/financial_lets_be_rational.jl): the solver. Constants are `@irrational`
  (exact for `BigFloat`, no promotion for `Float32`); keep them so. `blimpv_lets_be_rational` promotes its inputs to a
  common type first (`sqrt` of an `Int` strike is a `Float64`), and solves `Float16` in `Float32` (some approximations
  return `Float64` for it, and `erfinv(::Float16)` is wrong).
- [src/financial_value_and_partials.jl](src/financial_value_and_partials.jl): `value_and_partials(f, inputs...,
  parameters)`, the value and all the partials in closed form of `blsprice`, `blkprice`, `blsimpv` and `blkimpv`. Used by the ReverseDiff extension and by the ChainRules `rrule`s of the broadcasts of
  the four public functions: one fused pass, partials as thunks, gradients reduced over the broadcast dimensions.
  Without them Zygote reruns a GPU broadcast once per argument with duals (5-8 times slower than the CPU in Float64).
- Domain checks: `blcheck(S0, K, T[, σ])` and `check_positive(x, message)` (src/financial.jl), argument by argument
  through `domain_value` (real part of a complex, constant term of a Taylor series, `nothing` for symbolic values: the
  extensions add methods). Reuse `check_positive` for new checks; messages are constant strings (GPU kernels).
- [src/dates.jl](src/dates.jl): `yearfrac` (Matlab bases 0-7), `daysact`, `fromExcelNumberToDate`.
- [ext/](ext/): one extension per AD backend or number type. ForwardDiff, DualNumbers, HyperDualNumbers and
  Mooncake's `Nfwd.NDual` (Mooncake inside GPU broadcasts) solve on the values and add
  `(price - blprice(σ)) / vega`. ReverseDiff records `blsprice`, `blkprice`, `blsimpv` and `blkimpv`
  as single tape instructions written by hand (with `value_and_partials`): `ReverseDiff.@grad` keeps the pullback of the point where a
  compiled tape was recorded, so its gradients elsewhere are wrong. Enzyme has `forward`/`augmented_primal`/`reverse`
  rules for `blimpv`. DualNumbers also defines `normcdf`, `normpdf` and `internal_sqrt` of a `Dual` (its own `erfc`,
  `sqrt` promote to Float64 and its `x^2` is slow); HyperDualNumbers `normcdf` and `internal_sqrt`. TaylorSeries/TaylorDiff define `erfc` of a series (a coefficient recurrence) and the implied
  volatility by Newton on the whole series.
- [docs/](docs/): Documenter, in the style of the other packages of rcalxrc08 (`docs/src/assets/style.css` is shared,
  copy changes across). `docs/figures.jl` computes the figures at build time, a light and a dark SVG each; the
  performance table is measured at build time too; the GPU page (`gpu.md`) has a static table measured on an MX150,
  since CI has no GPU. Markdown tables need `|:--|` columns.
  The design is shared by all the rcalxrc08 docs (identical copies, edit together): `style.css` (Dark Quant),
  `dark.js`, `figures.css`, `site.css` (page headers with kicker, lede and section links, numbered sections, cards) and
  `home.css` (landing page: hero, stat tiles, feature cards, flow, tabbed results, quick start steps); `docs/surface.jl`
  draws the hero, the gamma surface of `blsgamma` in perspective. The home page's stat tiles are timed at build time by
  `hero_stats()` in `figures.jl` (called from a hidden `@example` block). The sidebar groups Guides and Reference.
  The calibration example of `gpu.md` runs at build time on the CPU (the same code runs on CUDA inside a function):
  an SVI-type smile (nonlinear in its parameters) fitted on implied volatilities by Gauss-Newton with
  `Zygote.jacobian`, on prices with deterministic 1% noise so that the residuals do not vanish and the Hessian differs
  from `JᵀJ`. The sensitivities to the quoted prices chain two implicit function theorems: `∂θ*/∂v = H⁻¹Jᵀ` (`H` from
  `ForwardDiff.hessian`) and `∂v/∂m = 1/vega` (the AD rules of `blsimpv`). They are checked against bumping a price,
  re-implying and recalibrating, and against the pseudo-inverse; keep the noise, without it the check cannot tell the
  two apart. In top-level loops of `@example` blocks update globals in place (`θ .-= ...`, Documenter's soft scope).
  `references.md` holds the bibliography; cite from the text with links to its sections.

## Benchmarks

`benchmark/benchmarks.jl` is the suite of BenchmarkCI (CI compares a pull request with master, a push with the
previous commit): scalar calls in Float64,
Float32, Float16, DualNumbers and the gradients of Zygote, Mooncake and ReverseDiff, and a smile of 1000 options
(broadcast rules). After adding or renaming a benchmark, rerun `benchmark/tune.jl` and commit `tune.json`.
`benchmark/gpu/run.jl` regenerates the GPU table of the docs (static, CI has no GPU).

## Tests

Coverage is on codecov (100% before the GPU work): code reached only on GPUs (Mooncake's `NDual`) or by
compiled tapes needs a CPU test that calls it directly.


`test/runtests.jl` runs every file of `TEST_FILES` (a new file must be added there) in a module of its own, from the
file's directory, inside a testset. Each file includes `test/setup.jl` (Test, FinancialToolbox, the reference option
`REFERENCE`, the Matlab values `MATLAB`, `closed_form_greeks`), so it also runs alone. Layout:
- `core/`: `pricing.jl` (Matlab values, BigFloat/Float32/Float16, input validation), `implied_volatility.jl` (round
  trips, accuracy grids in Float64 and Float32 against BigFloat), `implied_volatility_dataset.jl` with its `.json`
  (prices and implied volatilities of a reference dataset, round trips; it reads the JSON by a relative path, hence
  the `cd`), `dates.jl`, `element_types.jl`: Float32 in, Float32 out,
  for every function, input position and number type. Type-stability checks do not catch a promotion to a
  well-defined wider type (#74), this test does.
- `numbers/`: `complex.jl` (complex step), `dual_numbers.jl` (ForwardDiff, DualNumbers, HyperDualNumbers in one loop
  against the closed form Greeks), `taylor_series.jl`, `taylor_diff.jl`, `symbolics.jl` (derivatives not simplified:
  simplification is slow).
- `ad/`: `zygote.jl`, `broadcast_rules.jl` (the broadcast rules against ForwardDiff, for every argument and broadcast
  shape), `reversediff.jl` (evaluates compiled tapes away from the recording point: the only test of the forward pass
  of the hand-written instructions), `mooncake.jl`, `enzyme.jl`.
- `gpu/jlarrays.jl` runs `gpu/gpu_suite.jl` on JLArrays (GPU code path without a GPU, on CI); `test/cuda/` runs the same
  suite and `ad_suite.jl` (ForwardDiff, DualNumbers, Zygote, Mooncake, Enzyme in kernels) on CUDA, locally only.
  CI has no GPU: run the CUDA tests locally (this machine has an NVIDIA GPU) before pushing any change to `src/` or
  `ext/`, together with the CPU suite. JLArrays does not catch everything CUDA rejects (allocations, dynamic dispatch,
  strings built at run time in kernels).
- `aqua.jl`: Aqua (ambiguities, stale dependencies, compat, piracy, ...).

Keep the tests lean: a property checked once per code path, not once per number type (input validation is generic
code, the Greeks are checked against Matlab once, the number types against `closed_form_greeks`).

The test environment caps ChainRules at 1.74.10: 1.74.11 breaks the precompilation of TaylorDiff
(JuliaDiff/TaylorDiff.jl#113). Lift the cap once that is fixed, and close CompatHelper PRs that remove it before.

## Conventions

- Optimize: measure (BenchmarkTools, `@allocated`) and keep the faster version, unless it breaks a supported number
  type (e.g. `sqrt(F * K)` overflows `Float16`).
- No `Float64` constants or buffers in generic code: use `@irrational`, integer literals or `one`/`zero` of the input
  type. Upstream rules that promote are wrapped in the extensions (`normcdf`, `internal_sqrt` for DualNumbers and
  HyperDualNumbers).
- Code reachable from GPU kernels must not allocate and must not index arrays element by element.
- Prefer `x^2` to `x * x` in generic code: the same for hardware floats, faster for BigFloat, complex and Taylor
  series.
- Every exported function documents all its arguments in its docstring.
- Formatting: JuliaFormatter, `margin = 1200`.

## Known upstream issues

- SpecialFunctions `erfinv(::Float16)` is wrong for `|x| <= 0.75` (JuliaMath/SpecialFunctions.jl#571): Float16 is
  solved in Float32.
- ForwardDiff `gradient`/`jacobian` do not support GPU arrays (JuliaDiff/ForwardDiff.jl#759): broadcast
  `ForwardDiff.derivative` per element instead.
- Enzyme custom rules miss CUDA's device overrides inside kernels (EnzymeAD/Enzyme.jl#3962): `blsimpv` cannot be
  differentiated with Enzyme in kernels (`@test_broken` in `test/cuda/ad_suite.jl`).

## Releasing

Bump `version` in `Project.toml`, push to `master`, wait for CI, then comment `@JuliaRegistrator register` on the
commit. TagBot creates the tag and the release; if it opens a "manual intervention" issue, create the release at the
registered commit with `gh release create vX.Y.Z --target <full sha> --latest=false` (for an old version).

Keep this file up to date at every push.
