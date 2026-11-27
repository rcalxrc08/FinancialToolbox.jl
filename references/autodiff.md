# Automatic differentiation and number types

_What each backend needs and why._ (Layer 3 reference.)

- ChainRules (Zygote): `frule`/`rrule` of `blprice_impl` (closed-form partials) and of `blimpv` (implicit function
  theorem); broadcast `rrule`s of `blsprice`, `blkprice`, `blsimpv`, `blkimpv` through `value_and_partials` (one fused
  pass, partials as thunks, gradients reduced over the broadcast dimensions). Without them Zygote reruns a GPU
  broadcast once per argument with duals (5-8 times slower than the CPU in Float64).
- ForwardDiff, DualNumbers, HyperDualNumbers and Mooncake's `Nfwd.NDual` (Mooncake inside GPU broadcasts) solve the
  implied volatility on the values and add `(price - blprice(σ)) / vega`.
- DualNumbers also defines `normcdf` and `internal_sqrt` of a `Dual` (its own `erfc` and `sqrt` promote to Float64;
  `normpdf` needs nothing since `square` is a product); HyperDualNumbers `normcdf` and `internal_sqrt`.
- TaylorSeries defines `erfc` of a series (a coefficient recurrence: one pass with `@inbounds`/`muladd` for scalar
  `Taylor1`, a generic one for `TaylorN` and nested series). The coefficients of a `TaylorN` are built from the input's own
  polynomials (`zero(a[k])`), never from an order: those land in the global default `JetSpace`, which since TaylorSeries
  0.23 need not be the input's (#91). TaylorSeries and TaylorDiff both define the implied
  volatility by Newton on the whole series. TaylorDiff needs no `normcdf`: its own `erfc` (fixed in 0.3.6, the compat
  floor) is exact, keeps Float32, does not allocate, runs in GPU kernels and is faster than the recurrence the extension
  had until then (removed 2026-11-18).
- ReverseDiff records `blsprice`, `blkprice`, `blsimpv` and `blkimpv` as single tape instructions written by hand (with
  `value_and_partials`): `ReverseDiff.@grad` keeps the pullback of the point where a compiled tape was recorded, so its
  gradients elsewhere are wrong.
- Mooncake: `@from_chainrules` for the closed-form rules; the checks are `@zero_adjoint` (Mooncake does not read
  `@non_differentiable`).
- Enzyme: `forward`/`augmented_primal`/`reverse` rules for `blimpv`; the checks are found inactive by Enzyme itself.
  Tests reach the closure of each case through a function barrier (`enzyme_gradient`): through a dynamic call Enzyme
  asks for a shadow of the captured case and fails.
- Symbolics: `domain_value(::Num)` is `nothing` (no check); `blimpv` is a registered symbolic function with its
  derivative; derivatives are not simplified in tests (slow).
- Reactant (XLA): `domain_value(::TracedRNumber)` is `nothing`, as for Symbolics: the checks would branch on traced
  values. Enzyme differentiates the compiled prices (reverse and forward). `blsimpv` does not compile: Let's Be
  Rational branches on values and loops until convergence (#92).
- Complex numbers: complex step through the whole code; the implied volatility by Newton (analytic continuation).
- Zygote and branches: see `conventions.md` and the upstream issues in `dependencies.md` (FluxML/Zygote.jl#1736, #1751;
  #1752 and #1754 fixed in Zygote 0.7.19, which the tests require: a branch now costs Zygote no more than a select, D-005).
