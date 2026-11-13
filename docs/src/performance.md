```@raw html
<div class="fc-page-head">
<p class="fc-kicker"><span>Guide 05</span> Timed on the machine that builds this page</p>
```

# Performance

Time to compute the price and the implied volatility, and their gradients with respect to all the six inputs with
the AD backends the package is tested with (DualNumbers, HyperDualNumbers and TaylorDiff aside): forward mode with ForwardDiff, TaylorSeries (order one `TaylorN` in the
six inputs) and Enzyme (batched, the six tangents in one pass), reverse mode with Zygote, ReverseDiff (compiled tape), Mooncake and Enzyme. Caches, tapes and
configurations are prepared once, outside the timings, and every gradient is checked against ForwardDiff. The table is
generated when this documentation is built, on the machine that builds it.

```@raw html
<div class="fc-meta"><span>BenchmarkTools</span><span>gradients</span><span class="is-live">computed at build time</span></div>
</div>
```

```@eval
using FinancialToolbox, BenchmarkTools, Enzyme, ForwardDiff, Mooncake, ReverseDiff, TaylorSeries, Zygote, Printf, Logging, Markdown
S0 = 100.0; K = 100.0; r = 0.02; T = 1.2; σ = 0.2; d = 0.01
price = blsprice(S0, K, r, T, σ, d)
# TaylorN variables of order 1: the gradient is in the first order coefficients (set_variables before TaylorSeries 0.23)
taylorn_variables(names; order) = isdefined(TaylorSeries, :variables!) ? TaylorSeries.variables!(names; order = order) : TaylorSeries.set_variables(names; order = order)
dx = with_logger(NullLogger()) do
    taylorn_variables("x1 x2 x3 x4 x5 x6", order = 1)
end
format_time(t) = t < 1e-6 ? @sprintf("%.0f ns", 1e9 * t) : t < 1e-3 ? @sprintf("%.2f μs", 1e6 * t) : @sprintf("%.2f ms", 1e3 * t)
format_ratio(x) = x < 10 ? @sprintf("%.1f×", x) : @sprintf("%.0f×", x)
# Each backend: a gradient with respect to the six inputs, prepared once (cache, tape, configuration) and timed
function gradients(f, args)
    x = collect(args)
    f_vector = x -> f(x...)
    forwarddiff_config = ForwardDiff.GradientConfig(f_vector, x, ForwardDiff.Chunk{6}())
    x_taylor = args .+ dx
    reversediff_tape = ReverseDiff.compile(ReverseDiff.GradientTape(f_vector, x))
    reversediff_out = similar(x)
    mooncake_cache = Mooncake.prepare_gradient_cache(f, args...)
    # batched forward mode: the six one-hot tangents in one pass
    enzyme_tangents = ntuple(i -> BatchDuplicated(args[i], ntuple(j -> Float64(i == j), 6)), 6)
    return [
        "ForwardDiff" => (() -> ForwardDiff.gradient(f_vector, x, forwarddiff_config), identity),
        "TaylorSeries" => (() -> f(x_taylor...), y -> [TaylorSeries.getcoeff(y, [i == j ? 1 : 0 for j = 1:6]) for i = 1:6]),
        "Enzyme forward" => (() -> Enzyme.autodiff(Enzyme.Forward, Const(f), enzyme_tangents...), y -> collect(values(y[1]))),
        "Zygote" => (() -> Zygote.gradient(f, args...), collect),
        "ReverseDiff" => (() -> ReverseDiff.gradient!(reversediff_out, reversediff_tape, x), identity),
        "Mooncake" => (() -> Mooncake.value_and_gradient!!(mooncake_cache, f, args...), y -> collect(y[2][2:end])),
        "Enzyme reverse" => (() -> Enzyme.autodiff(Enzyme.Reverse, Const(f), Active, Active.(args)...), y -> collect(y[1])),
    ]
end
function performance_row(f, args)
    t = @belapsed $f($(args)...)
    reference = ForwardDiff.gradient(x -> f(x...), collect(args))
    cells = String[format_time(t)]
    for (name, (run, to_vector)) in gradients(f, args)
        # every gradient agrees with ForwardDiff
        @assert isapprox(to_vector(run()), reference; rtol = 1e-8) name
        t_gradient = @belapsed $run()
        push!(cells, "$(format_time(t_gradient)) ($(format_ratio(t_gradient / t)))")
    end
    return cells
end
io = IOBuffer()
backends = first.(gradients(blsprice, (S0, K, r, T, σ, d)))
println(io, "| Function | Value | ", join(backends, " | "), " |")
println(io, "|:--|", repeat("--:|", length(backends) + 1))
for (name, f, args) in (("blsprice", blsprice, (S0, K, r, T, σ, d)), ("blsimpv", blsimpv, (S0, K, r, T, price, d)))
    println(io, "| `", name, "` | ", join(performance_row(f, args), " | "), " |")
end
println(io)
@printf(io, "Julia %s, %s, FinancialToolbox %s; minimum time over the BenchmarkTools samples, in brackets the ratio to the value.\n", VERSION, strip(Sys.cpu_info()[1].model), pkgversion(FinancialToolbox))
Markdown.parse(String(take!(io)))
```

The gradient of the implied volatility in reverse mode costs about as much as the implied volatility itself: the
solver is not differentiated, and the derivatives come from the closed form sensitivities at the solution (see
[Automatic differentiation](ad.md)).

A broader suite, covering `blsprice`, `blsvega` and `blsimpv` in `Float64` and `Float32`, with DualNumbers and with
the gradients of Zygote and Mooncake, is in
[`benchmark`](https://github.com/rcalxrc08/FinancialToolbox.jl/tree/master/benchmark) and runs on CI; locally:

```sh
julia benchmark/run.jl
```
