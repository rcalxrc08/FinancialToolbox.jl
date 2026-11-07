# The ChainRules rules of the broadcasts of blsprice, blkprice, blsimpv and blkimpv (src/financial_value_and_partials.jl),
# through Zygote, against ForwardDiff: every argument, flags as arrays, broadcasts along different dimensions.
using FinancialToolbox, Test, Zygote, ForwardDiff

@testset "Broadcast rules" begin
    S0, r, T, d = 100.0, 0.02, 1.2, 0.01
    K = collect(range(70.0, 140.0, length = 7))
    σs = collect(range(0.15, 0.35, length = 7))
    w = collect(1.0:7.0)
    P = blsprice.(S0, K, r, T, σs, d)
    PB = blkprice.(S0, K, r, T, σs)
    cases = (("blsprice", blsprice, (S0, K, r, T, σs, d)), ("blkprice", blkprice, (S0, K, r, T, σs)), ("blsimpv", blsimpv, (S0, K, r, T, P, d)), ("blkimpv", blkimpv, (S0, K, r, T, PB)))
    for (name, f, args) in cases
        @testset "$name" begin
            loss(a...) = sum(w .* f.(a...))
            g = Zygote.gradient(loss, args...)
            for i in eachindex(args)
                replace_arg(x) = ntuple(j -> j == i ? x : args[j], length(args))
                ref = args[i] isa Number ? ForwardDiff.derivative(x -> loss(replace_arg(x)...), args[i]) : ForwardDiff.gradient(x -> loss(replace_arg(x)...), args[i])
                @test g[i] ≈ ref
            end
        end
    end
    # calls and puts as an array of flags, and a put given as a scalar flag
    flags = [isodd(i) for i = 1:7]
    Pf = blsprice.(S0, K, r, T, σs, d, flags)
    @test only(Zygote.gradient(p -> sum(blsimpv.(S0, K, r, T, p, d, flags)), Pf)) ≈ ForwardDiff.gradient(p -> sum(blsimpv.(S0, K, r, T, p, d, flags)), Pf)
    @test only(Zygote.gradient(s -> sum(blsprice.(S0, K, r, T, s, d, false)), 0.2)) ≈ ForwardDiff.derivative(s -> sum(blsprice.(S0, K, r, T, s, d, false)), 0.2)
    # a grid of strikes × maturities: gradients summed over the broadcast dimensions
    Ts = [0.5 1.0 2.0]
    Pm = blsprice.(S0, K, r, Ts, 0.2, d)
    g = Zygote.gradient((k, t) -> sum(blsimpv.(S0, k, r, t, Pm, d)), K, Ts)
    @test g[1] ≈ ForwardDiff.gradient(k -> sum(blsimpv.(S0, k, r, Ts, Pm, d)), K)
    @test g[2] ≈ ForwardDiff.gradient(t -> sum(blsimpv.(S0, K, r, t, Pm, d)), Ts)
    # the element type is kept
    @test eltype(only(Zygote.gradient(p -> sum(blsimpv.(100.0f0, Float32.(K), 0.02f0, 1.2f0, p, 0.01f0)), Float32.(P)))) == Float32
end
