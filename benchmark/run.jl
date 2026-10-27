# Run the suite with the parameters in tune.json and print the summary table: `julia benchmark/run.jl`
include(joinpath(@__DIR__, "environment.jl"))
include(joinpath(@__DIR__, "benchmarks.jl"))
include(joinpath(@__DIR__, "summary.jl"))

loadparams!(SUITE, BenchmarkTools.load(joinpath(@__DIR__, "tune.json"))[1], :evals, :samples)
results = run(SUITE; verbose = true)
summary_table(stdout, results)
