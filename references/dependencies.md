# Dependencies

_Why each dependency exists, hard or weak, and its compat floor._ (Layer 3 reference.)

| Package | Hard/weak | Why | Compat floor and why |
|:--|:--|:--|:--|
| `ChainRulesCore` | hard | `frule`/`rrule` of the closed forms and of the broadcasts | 1 |
| `Dates` | hard | day counts | stdlib |
| `IrrationalConstants` | hard | constants | 0.2.3 |
| `MuladdMacro` | hard | `@muladd` | 0.2 |
| `SpecialFunctions` | hard | `erfc`, `erfinv` | `erfinv(::Float16)` correct since 2.9.2 (JuliaMath/SpecialFunctions.jl#571) |
| `ForwardDiff`, `DualNumbers`, `HyperDualNumbers` | weak | implied volatility and promoting functions on duals | ForwardDiff 0.10 or 1; HyperDualNumbers 4 |
| `TaylorSeries`, `TaylorDiff` | weak | `erfc` of a series, Newton on the series | TaylorDiff 0.3.6 (exact `erfc`, JuliaDiff/TaylorDiff.jl#113) |
| `Mooncake` | weak | `@from_chainrules`, `@zero_adjoint`, `NDual` | 0.5 |
| `EnzymeCore` | weak | Enzyme rules for `blimpv` | 0.8 |
| `ReverseDiff` | weak | hand-written tape instructions | 1 |
| `Reactant` | weak | `domain_value(::TracedRNumber)` | 0.2.309 (the version tested; Enzyme 0.13.220) |
| `Symbolics` | weak | `domain_value(::Num)`, registered `blimpv` | 7 |

Julia floor 1.10 (CI tests 1.10 and 1; AutoMerge could not start Julia 1.9.4 on its runner, "libopenlibm.so: cannot
enable executable stack"). Test environments: Enzyme ≥ 0.13.220 (EnzymeAD/Enzyme.jl#4051, the abort on Julia 1.13.4).

Upstream workarounds (cite issue and version; recheck on every upstream release, remove when fixed):

| Workaround | Upstream issue | Affected versions | Last checked |
|:--|:--|:--|:--|
| `Float16` solved in `Float32` | JuliaMath/SpecialFunctions.jl#571 (fixed in 2.9.2); kept because some approximations return Float64 for Float16 | < 2.9.2 | 2026-11-18 |
| broadcast `ForwardDiff.derivative` on GPU arrays | JuliaDiff/ForwardDiff.jl#759 | ForwardDiff 1 | 2026-11-19 |
| `@test_broken` Enzyme `blsimpv` in CUDA kernels | EnzymeAD/Enzyme.jl#3962 | Enzyme 0.13 | 2026-11-19 |
| `@test_broken` Reactant barrier prices on Windows (`___chkstk_ms` not found by the XLA CPU JIT) | not reported yet | Reactant 0.2.309 (Reactant_jll 0.0.447) | 2026-11-27 |
| branch-free code, `promote` instead of `oftype`, Zygote benchmarks without splats | FluxML/Zygote.jl#1736, #1751 (open); #1752, #1754 fixed in Zygote 0.7.19 (reported 2026-11-19 from FinancialCalibrator#39) | Zygote 0.7.19 | 2026-11-22 |

Resolved: TaylorDiff 0.3.6 (2026-11-12) fixed its `erfc` and the precompilation with ChainRules 1.74.11
(JuliaDiff/TaylorDiff.jl#113): the own `normcdf(::TaylorScalar)` and the ChainRules cap were removed on 2026-11-18.
Enzyme 0.13.220 fixed the abort on Julia 1.13.4 (#4051): CI is back to '1' (it pinned 1.13.3 from 2026-11-14 to
2026-11-18).
