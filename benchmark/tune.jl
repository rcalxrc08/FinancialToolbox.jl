# Tune the suite and save the parameters to tune.json (used by run.jl and by PkgBenchmark on CI):
# `julia benchmark/tune.jl`
include(joinpath(@__DIR__, "environment.jl"))
include(joinpath(@__DIR__, "benchmarks.jl"))

tune!(SUITE; verbose = true)
BenchmarkTools.save(joinpath(@__DIR__, "tune.json"), params(SUITE))
