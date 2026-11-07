# GPU against CPU on broadcasts over n options, as in a calibration: the table of docs/src/gpu.md. Needs an NVIDIA GPU,
# not run on CI:
#     julia --project=benchmark/gpu -e 'import Pkg; Pkg.instantiate(); include("benchmark/gpu/run.jl")'
# Prints a Markdown table with the minimum times on the CPU (one thread) and on the GPU, and the allocations of each.
using FinancialToolbox, CUDA, BenchmarkTools, ForwardDiff, Zygote, Printf
CUDA.functional() || error("CUDA is not functional on this machine")
CUDA.allowscalar(false)

format_time(t) = t < 1e-3 ? @sprintf("%.1f μs", 1e6t) : @sprintf("%.2f ms", 1e3t)

function benchmark_operations(Tp, n)
    S0, r, T, d, σ = Tp(100), Tp(0.02), Tp(1.2), Tp(0.01), Tp(0.2)
    strikes = Tp.(collect(range(70, 140, length = n)))
    prices = blsprice.(S0, strikes, r, T, σ, d)
    K, P = CuArray(strikes), CuArray(prices)
    # loss of a calibration of σ against the prices, and the sum of the implied volatilities
    loss_σ(s, K, P) = sum(abs2, blsprice.(S0, K, r, T, s, d) .- P .* Tp(1.01))
    loss_P(P, K) = sum(blsimpv.(S0, K, r, T, P, d))
    return (
        ("`blsprice`", () -> blsprice.(S0, strikes, r, T, σ, d), () -> CUDA.@sync(blsprice.(S0, K, r, T, σ, d))),
        ("`blsimpv`", () -> blsimpv.(S0, strikes, r, T, prices, d), () -> CUDA.@sync(blsimpv.(S0, K, r, T, P, d))),
        ("ForwardDiff, calibration loss", () -> ForwardDiff.derivative(s -> loss_σ(s, strikes, prices), σ), () -> ForwardDiff.derivative(s -> loss_σ(s, K, P), σ)),
        ("Zygote, gradient w.r.t. the prices", () -> Zygote.gradient(p -> loss_P(p, strikes), prices), () -> CUDA.@sync(Zygote.gradient(p -> loss_P(p, K), P))),
    )
end

println("CPU: ", strip(Sys.cpu_info()[1].model), ", ", Threads.nthreads(), " thread(s); GPU: ", CUDA.name(CUDA.device()), "; Julia ", VERSION, ", FinancialToolbox ", pkgversion(FinancialToolbox))
println()
println("| Operation | Type | n | CPU | GPU | Speedup | CPU allocations | GPU allocations |")
println("|:--|:--|--:|--:|--:|--:|--:|--:|")
for Tp in (Float32, Float64), n in (10^3, 10^4, 10^5, 10^6)
    for (name, cpu, gpu) in benchmark_operations(Tp, n)
        cpu(); gpu()
        t_cpu = @belapsed $cpu() seconds = 2 samples = 200
        t_gpu = @belapsed $gpu() seconds = 2 samples = 200
        a_cpu = @allocated cpu()
        a_gpu = CUDA.@allocated gpu()
        @printf("| %s | %s | %d | %s | %s | %.1f× | %d B | %d B |\n", name, Tp, n, format_time(t_cpu), format_time(t_gpu), t_cpu / t_gpu, a_cpu, a_gpu)
        flush(stdout)
    end
end
