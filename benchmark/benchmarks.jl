# Benchmark suite of FinancialToolbox: SUITE[function][input]. On CI it is run by BenchmarkCI (PkgBenchmark), which
# loads the tuning parameters from tune.json. Locally: `julia benchmark/run.jl` runs it and prints a summary table,
# `julia benchmark/tune.jl` retunes it and saves tune.json.
using BenchmarkTools, FinancialToolbox, DualNumbers, Mooncake, Zygote

const S0, K, r, T, σ, d = 100.0, 100.0, 0.01, 1.0, 0.2, 0.01

# Functions with their Float64 inputs
const BENCHMARKED_FUNCTIONS = (
    "blsprice" => (blsprice, (S0, K, r, T, σ, d)),
    "blsvega" => (blsvega, (S0, K, r, T, σ, d)),
    "blsimpv" => (blsimpv, (S0, K, r, T, blsprice(S0, K, r, T, σ, d), d)),
)

# Inputs: Float64 and Float32 values, the derivative with respect to S0 with DualNumbers, gradients with respect to
# all the inputs in reverse mode with Zygote and Mooncake
function function_group(f, x)
    group = BenchmarkGroup()
    x32 = Float32.(x)
    x_dual = (Dual(x[1], one(x[1])), Base.tail(x)...)
    mooncake_cache = Mooncake.prepare_gradient_cache(f, x...)
    group["Float64"] = @benchmarkable $f($(x)...)
    group["Float32"] = @benchmarkable $f($(x32)...)
    group["DualNumbers ∂/∂S0"] = @benchmarkable $f($(x_dual)...)
    group["Zygote gradient"] = @benchmarkable Zygote.gradient($f, $(x)...)
    group["Mooncake gradient"] = @benchmarkable Mooncake.value_and_gradient!!($mooncake_cache, $f, $(x)...)
    return group
end

const SUITE = BenchmarkGroup()
for (name, (f, x)) in BENCHMARKED_FUNCTIONS
    SUITE[name] = function_group(f, x)
end
