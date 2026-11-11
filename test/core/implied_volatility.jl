# Implied volatility (Black & Scholes and Black): round trips σ -> price -> σ on selected options, and the accuracy on a
# grid of moneyness, maturities and volatilities against BigFloat references.
include(joinpath(@__DIR__, "..", "setup.jl"))

@testset "Round trips" begin
    toll = 1e-10
    # (S0, K, r, T, σ, d), recovered for calls and puts
    cases = [
        (100.0, 100.0, 0.02, 1.2, 0.2, 0.01),
        (100.0, 90.0, 0.02, 1.2, 0.2, 0.03),
        (100.0, 120.0, 0.02, 1.2, 0.2, 0.03),
        (160.0, 120.0, 0.03, 1.2, 0.2, 0.03),
        (100.0, 70.0, 0.02, 1.2, 3.5, 0.01), # high volatility
        (100.0, 100.0, 0.2, 1.2, 0.2, 0.01), # high rate
        (100.0, 100.0, 0.02, 0.2, 0.2, 0.01), # short maturity
        (100.0, 100.0, 0.02, 1.2, 0.2, 0.1), # high dividend
        (100.0, 100.0, 0.02, 10.2, 0.2, 0.01), # long maturity
    ]
    for (S0, K, r, T, σ, d) in cases, FlagIsCall in (true, false)
        @test abs(blsimpv(S0, K, r, T, blsprice(S0, K, r, T, σ, d, FlagIsCall), d, FlagIsCall) - σ) < toll
        @test abs(blkimpv(S0, K, r, T, blkprice(S0, K, r, T, σ, FlagIsCall), FlagIsCall) - σ) < toll
    end
    # deep in the money: the time value (~1e-30) is below the precision of the price, σ is not recoverable; the out of
    # the money option is
    for (S0, K, FlagIsCall) in ((100.0, 10.0, true), (10.0, 100.0, false))
        @test_broken abs(blsimpv(S0, K, 0.02, 1.2, blsprice(S0, K, 0.02, 1.2, 0.2, 0.01, FlagIsCall), 0.01, FlagIsCall) - 0.2) < toll
        @test abs(blsimpv(S0, K, 0.02, 1.2, blsprice(S0, K, 0.02, 1.2, 0.2, 0.01, !FlagIsCall), 0.01, !FlagIsCall) - 0.2) < toll
    end
    # σ√T too large: the price is the upper bound in Float64
    for (K, T) in ((70.0, 1.2), (100.0, 1.0)), FlagIsCall in (true, false)
        @test_broken abs(blsimpv(100.0, K, 0.02, T, blsprice(100.0, K, 0.02, T, 13.5, 0.01, FlagIsCall), 0.01, FlagIsCall) - 13.5) < toll
        @test_broken abs(blkimpv(100.0, K, 0.02, T, blkprice(100.0, K, 0.02, T, 13.5, FlagIsCall), FlagIsCall) - 13.5) < toll
    end
    # issue #21
    S0, K, r, T, d = 4753.63, 4085.0, 0.0525, 0.13870843734533175, 0.0
    σ = blsimpv(S0, K, r, T, 701.3994, d)
    @test !isnan(σ)
    for FlagIsCall in (true, false)
        @test abs(blsimpv(S0, K, r, T, blsprice(S0, K, r, T, σ, d, FlagIsCall), d, FlagIsCall) - σ) < toll
    end
end

# The error must be within a small factor of the attainable accuracy (1 + κ)·ε, κ = price / (vega·σ).
@testset "Accuracy on a grid, Float64" begin
    max_excess = 0.0
    F = 100.0
    for FlagIsCall in (true, false), k in exp.(range(log(0.2), log(5.0), length = 21)), T in (0.01, 0.25, 2.0, 10.0), σ in (0.01, 0.05, 0.2, 0.5, 1.0, 2.0, 3.0)
        K = F * k
        price_big, κ = setprecision(BigFloat, 256) do
            p = FinancialToolbox.blprice_impl(big(F), big(K), big(T), big(σ), FlagIsCall)
            p, Float64(p / (FinancialToolbox.blvega_impl(big(F), big(K), big(T), big(σ)) * σ))
        end
        price = Float64(price_big)
        (price > max(FlagIsCall ? F - K : K - F, 0.0) && price < (FlagIsCall ? F : K)) || continue
        σ_impl = FinancialToolbox.blimpv(F, K, T, price, FlagIsCall, 1e-14, 4)
        max_excess = max(max_excess, abs(σ_impl - σ) / σ / (eps() * (1 + κ)))
    end
    @test max_excess < 10
end

# Float32 is computed in Float32; the reference is the BigFloat implied volatility of the Float32 inputs
@testset "Accuracy on a grid, Float32" begin
    max_excess = 0.0
    F = 100.0f0
    for FlagIsCall in (true, false), k in exp.(range(log(0.2), log(5.0), length = 11)), T in (0.01f0, 2.0f0), σ in (0.05f0, 0.2f0, 1.0f0)
        K = Float32(F * k)
        price = Float32(FinancialToolbox.blprice_impl(big(F), big(K), big(T), big(σ), FlagIsCall))
        intrinsic = max(FlagIsCall ? F - K : K - F, 0.0f0)
        # prices whose normalised time value is subnormal have too few significant bits
        (price > intrinsic && price < (FlagIsCall ? F : K) && (price - intrinsic) / sqrt(F * K) > floatmin(Float32)) || continue
        σ_ref, κ = setprecision(BigFloat, 256) do
            s = FinancialToolbox.blimpv(big(F), big(K), big(T), big(price), FlagIsCall, 1e-14, 8)
            s, Float64(price / (FinancialToolbox.blvega_impl(big(F), big(K), big(T), s) * s))
        end
        σ_impl = @inferred FinancialToolbox.blimpv(F, K, T, price, FlagIsCall, 1e-7, 4)
        @test σ_impl isa Float32
        max_excess = max(max_excess, Float64(abs(σ_impl - σ_ref) / σ_ref) / (eps(Float32) * (1 + κ)))
    end
    @test max_excess < 10
end
