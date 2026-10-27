# Markdown table of the results of the suite in benchmarks.jl: one row per function, one column per input.
# Each cell is the minimum time and, for the derivatives, its ratio to the Float64 value.
using BenchmarkTools, Printf

format_time(t) = t < 1e3 ? @sprintf("%.0f ns", t) : t < 1e6 ? @sprintf("%.2f μs", t / 1e3) : @sprintf("%.2f ms", t / 1e6)
minimum_time(x::BenchmarkTools.Trial) = time(minimum(x))
minimum_time(x::BenchmarkTools.TrialEstimate) = time(x)

function summary_table(io::IO, results::BenchmarkGroup)
    inputs = ("Float64", "Float32", "DualNumbers ∂/∂S0", "Zygote gradient", "Mooncake gradient")
    println(io, "| Function | ", join(inputs, " | "), " |")
    println(io, "|:--", repeat("|--:", length(inputs)), "|")
    for name in sort(collect(keys(results)))
        group = results[name]
        t_value = minimum_time(group["Float64"])
        cells = map(inputs) do input
            haskey(group, input) || return "-"
            t = minimum_time(group[input])
            input in ("Float64", "Float32") ? format_time(t) : @sprintf("%s (%.1f×)", format_time(t), t / t_value)
        end
        println(io, "| `", name, "` | ", join(cells, " | "), " |")
    end
    println(io)
    println(io, "Minimum time over the samples; in brackets the ratio to the Float64 value.")
end
