# Conventions

_Coding standards that hold in every stage._ (Layer 3 reference.)

- Optimize: measure (BenchmarkTools, `@allocated`) and keep the faster version, unless it breaks a supported number type
  (e.g. `sqrt(F * K)` overflows `Float16`).
- No `Float64` constants or buffers in generic code: use `@irrational`, integer literals or `one`/`zero` of the input
  type. Upstream rules that promote are wrapped in the extensions (`normcdf`, `internal_sqrt` for DualNumbers and
  HyperDualNumbers). Type-stability checks do not catch a promotion to a well-defined wider type (#74):
  `test/core/element_types.jl` does.
- Code reachable from GPU kernels does not allocate nor index element by element (`gpu.md`).
- No `if` on flags or values in differentiable code: Zygote is about 20 times slower on control flow (a barrier
  gradient, #80: 55 μs with `if FlagIsCall`, 2.8 μs branch free). Use `call_put_sign`, 0/1 weights derived from it,
  `max`/`min` and parity identities, so one formula covers every case. Compute directly the quantity used (the negated
  weight, `-inv_vega` once), not a value negated at each use. Domain checks (`check_positive`, non-differentiable) are
  the exception. On differentiated paths use `promote` or `convert(typeof(x), y)`, not `oftype` (a branch, #1751).
- `a * b + c` is `muladd(a, b, c)` (or `@muladd` of MuladdMacro on a whole function), frules and extensions included:
  one rounding, a fused multiply-add on CPUs and GPUs. Never negate an `Irrational` inside it (`c - π * x` becomes
  `muladd(-π, …)`, a Float64): keep the variable first.
- Squares and cubes are `square(x)` and `cube(x)`, never `x^2`/`x^3`: products, the same values, `x^2` is 1.3 times
  slower for BigFloat and 6 times for DualNumbers, `x^3` 1.8 times for BigFloat; the same for hardware floats, complex
  numbers, ForwardDiff and Taylor1. Specialize per number type where the power is faster: `square(::TaylorN)` is `x^2`
  in the TaylorSeries extension (1.5 times faster than the product).
- Every exported function documents all its arguments in its docstring.
- Reuse before writing: the author's packages, then established libraries.
- Formatting: JuliaFormatter, `margin = 1200` (`.JuliaFormatter.toml`).
