# Benchmark suite of FinancialToolbox: SUITE[function][input]. On CI it is run by BenchmarkCI (PkgBenchmark), which
# loads the tuning parameters from tune.json. Locally: `julia benchmark/run.jl` runs it and prints a summary table,
# `julia benchmark/tune.jl` retunes it and saves tune.json.
using BenchmarkTools, FinancialToolbox, DualNumbers, Mooncake, ReverseDiff, Zygote

const S0, K, r, T, σ, d = 100.0, 100.0, 0.01, 1.0, 0.2, 0.01

# Functions with their Float64 inputs
const BENCHMARKED_FUNCTIONS = (
    "blsprice" => (blsprice, (S0, K, r, T, σ, d)),
    "blsvega" => (blsvega, (S0, K, r, T, σ, d)),
    "blsimpv" => (blsimpv, (S0, K, r, T, blsprice(S0, K, r, T, σ, d), d)),
)

# Inputs: Float64, Float32 and Float16 values, the derivative with respect to S0 with DualNumbers, gradients with
# respect to all the inputs in reverse mode with Zygote, Mooncake and ReverseDiff (compiled tape)
function function_group(f, x)
    group = BenchmarkGroup()
    x32 = Float32.(x)
    x16 = Float16.(x)
    x_dual = (Dual(x[1], one(x[1])), Base.tail(x)...)
    mooncake_cache = Mooncake.prepare_gradient_cache(f, x...)
    x_vector = collect(x)
    reversediff_tape = ReverseDiff.compile(ReverseDiff.GradientTape(y -> f(y...), x_vector))
    reversediff_gradient = similar(x_vector)
    group["Float64"] = @benchmarkable $f($(x)...)
    group["Float32"] = @benchmarkable $f($(x32)...)
    group["Float16"] = @benchmarkable $f($(x16)...)
    group["DualNumbers ∂/∂S0"] = @benchmarkable $f($(x_dual)...)
    group["Zygote gradient"] = @benchmarkable Zygote.gradient($f, $(x)...)
    group["Mooncake gradient"] = @benchmarkable Mooncake.value_and_gradient!!($mooncake_cache, $f, $(x)...)
    group["ReverseDiff gradient"] = @benchmarkable ReverseDiff.gradient!($reversediff_gradient, $reversediff_tape, $x_vector)
    return group
end

# A smile of 1000 options, as in a calibration: the broadcast of blsimpv, and the gradients of the sum of the implied
# volatilities with respect to the prices (Zygote through the broadcast rule of the package)
function smile_group()
    group = BenchmarkGroup()
    strikes = collect(range(70.0, 140.0, length = 1000))
    prices = blsprice.(S0, strikes, r, T, σ, d)
    volatilities(p) = sum(blsimpv.(S0, strikes, r, T, p, d))
    mooncake_cache = Mooncake.prepare_gradient_cache(volatilities, prices)
    group["Float64"] = @benchmarkable blsimpv.($S0, $strikes, $r, $T, $prices, $d)
    group["Float32"] = @benchmarkable blsimpv.($(Float32(S0)), $(Float32.(strikes)), $(Float32(r)), $(Float32(T)), $(Float32.(prices)), $(Float32(d)))
    group["Zygote gradient"] = @benchmarkable Zygote.gradient($volatilities, $prices)
    group["Mooncake gradient"] = @benchmarkable Mooncake.value_and_gradient!!($mooncake_cache, $volatilities, $prices)
    return group
end

const SUITE = BenchmarkGroup()
for (name, (f, x)) in BENCHMARKED_FUNCTIONS
    SUITE[name] = function_group(f, x)
end
SUITE["blsimpv, smile of 1000 options"] = smile_group()
