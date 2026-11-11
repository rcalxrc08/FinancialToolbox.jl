# Every file runs in a module of its own (no names shared between files), from its own directory
# (core/implied_volatility_dataset.jl reads its JSON by a relative path), inside a testset. A file also runs alone:
#     julia --project=test -e 'include("test/core/pricing.jl")'
# The core tests come first, then the number types and the AD backends (slow to load), then the GPU and Aqua.
using Test

const TEST_FILES = [
    # prices, Greeks, implied volatility, dates
    "core/pricing.jl",
    "core/implied_volatility.jl",
    "core/implied_volatility_dataset.jl",
    "core/dates.jl",
    "core/element_types.jl",
    # number types of the extensions
    "numbers/complex.jl",
    "numbers/dual_numbers.jl",
    "numbers/taylor_series.jl",
    "numbers/taylor_diff.jl",
    "numbers/symbolics.jl",
    # AD backends
    "ad/zygote.jl",
    "ad/broadcast_rules.jl",
    "ad/reversediff.jl",
    "ad/mooncake.jl",
    "ad/enzyme.jl",
    # GPU code path on JLArrays, package quality
    "gpu/jlarrays.jl",
    "aqua.jl",
]

function run_test_file(file)
    path = joinpath(@__DIR__, file)
    name = Symbol("Test_", replace(file, r"[^A-Za-z0-9]" => "_"))
    elapsed = @elapsed @testset "$file" begin
        cd(dirname(path)) do
            Core.eval(Main, Expr(:module, true, name, Expr(:block, :(include($path)))))
        end
    end
    println(rpad(file, 40), round(elapsed, digits = 1), " s")
    return
end

@testset "FinancialToolbox" begin
    foreach(run_test_file, TEST_FILES)
end
