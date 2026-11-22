# Performance

_Where the numbers live and how to measure._ (Layer 3 reference; `benchmark/` updates them.)

| Numbers | Where | Conditions |
|:--|:--|:--|
| Scalar calls and gradients, a 1000-option smile | BenchmarkCI on each PR/push (`benchmark/benchmarks.jl`) | CI runner, compared with the base commit |
| Performance page | `docs/src/performance.md` | measured at build time on the building machine |
| GPU vs CPU | `docs/src/gpu.md` (static) | MX150, `benchmark/gpu/run.jl` |
| Branches under Zygote | `conventions.md` | barrier gradient 55 μs with `if`, 2.8 μs branch free (#80) |
| `x^2` vs `square` | `conventions.md` | BigFloat, DualNumbers, TaylorN |

How to measure:

- Zygote: interpolated non-constant arguments and no `$(args)...` splat: literals constant-fold the gradient, the splat
  adds its own run-time `_apply_iterate` (FluxML/Zygote.jl#1752: `gradient`/`pullback` are compiled for
  `f::Function`, microseconds of dynamic dispatch once the pullback is not inlined, 57 ns when specialized; it may also
  affect the Zygote rows of BenchmarkCI, not checked).
- After adding or renaming a benchmark, rerun `benchmark/tune.jl` and commit `tune.json`.
- Timings that get written down come from an idle machine and fresh processes; `@allocated` also on Julia 1.10
  (`gpu.md`).
