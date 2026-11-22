# GPU

_What GPU code must respect._ (Layer 3 reference.)

- Code reachable from GPU kernels must not allocate and must not index arrays element by element.
- Julia 1.13 removes small fixed-size `Vector`s (CPU and GPU), so a kernel that builds one works there and fails on
  1.10-1.12: check `@allocated` on Julia 1.10, not only on the local Julia (the old `normcdf(::TaylorScalar)`: 0 B on
  1.13, 288 B on 1.10).
- `CUDA.allowscalar(false)` only concerns host access to device arrays: it does not catch this.
- Messages of checks are constant strings: strings built at run time fail in kernels.
- JLArrays (`test/gpu/jlarrays.jl`, on CI) does not catch everything CUDA rejects (allocations, dynamic dispatch,
  strings built at run time in kernels): run `test/cuda/` locally before pushing a change to `src/` or `ext/`.
- ForwardDiff `gradient`/`jacobian` do not support GPU arrays (JuliaDiff/ForwardDiff.jl#759): broadcast
  `ForwardDiff.derivative` per element instead.
- Enzyme custom rules miss CUDA's device overrides inside kernels (EnzymeAD/Enzyme.jl#3962): `blsimpv` cannot be
  differentiated with Enzyme in kernels (`@test_broken` in `test/cuda/ad_suite.jl`).
- The GPU table of `docs/src/gpu.md` was measured on an MX150 (`benchmark/gpu/run.jl`).
