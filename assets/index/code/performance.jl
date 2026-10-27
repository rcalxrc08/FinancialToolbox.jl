# This file was generated, do not modify it. # hide
# hideall
using FinancialToolbox, BenchmarkTools, Mooncake, TaylorSeries, Printf, Logging
S0 = 100.0; K = 100.0; r = 0.02; T = 1.2; σ = 0.2; d = 0.01
price = blsprice(S0, K, r, T, σ, d)
# TaylorN variables of order 1: the gradient is in the first order coefficients (set_variables before TaylorSeries 0.23)
taylorn_variables(names; order) = isdefined(TaylorSeries, :variables!) ? TaylorSeries.variables!(names; order = order) : TaylorSeries.set_variables(names; order = order)
dx = with_logger(NullLogger()) do
    taylorn_variables("x1 x2 x3 x4 x5 x6", order = 1)
end
format_time(t) = t < 1e-6 ? @sprintf("%.0f ns", 1e9 * t) : t < 1e-3 ? @sprintf("%.2f μs", 1e6 * t) : @sprintf("%.2f ms", 1e3 * t)
function performance_row(io, name, f, args)
    t = @belapsed $f($(args)...)
    x_taylor = args .+ dx
    t_taylor = @belapsed $f($(x_taylor)...)
    cache = Mooncake.prepare_gradient_cache(f, args...)
    t_mooncake = @belapsed Mooncake.value_and_gradient!!($cache, $f, $(args)...)
    # both gradients agree
    g_taylor = [TaylorSeries.getcoeff(f(x_taylor...), [i == j ? 1 : 0 for j in 1:6]) for i in 1:6]
    g_mooncake = collect(Mooncake.value_and_gradient!!(cache, f, args...)[2][2:end])
    @assert isapprox(g_taylor, g_mooncake; rtol = 1e-8)
    @printf(io, "| `%s` | %s | %s (%.1f×) | %s (%.1f×) |\n", name, format_time(t), format_time(t_taylor), t_taylor / t, format_time(t_mooncake), t_mooncake / t)
end
# The table is written to a file and included below: printed output would also be shown as plain text (showall)
open(joinpath(@OUTPUT, "performance.md"), "w") do io
    println(io, "| Function | Value (Float64) | Gradient, TaylorSeries (TaylorN) | Gradient, Mooncake (reverse mode) |")
    println(io, "|:--|--:|--:|--:|")
    performance_row(io, "blsprice(S0, K, r, T, σ, d)", blsprice, (S0, K, r, T, σ, d))
    performance_row(io, "blsimpv(S0, K, r, T, price, d)", blsimpv, (S0, K, r, T, price, d))
    println(io)
    @printf(io, "Julia %s, %s, FinancialToolbox %s; minimum time over the BenchmarkTools samples, in brackets the ratio to the value.\n", VERSION, Sys.cpu_info()[1].model, pkgversion(FinancialToolbox))
end
nothing