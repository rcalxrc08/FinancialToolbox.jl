# TaylorDiff: normcdf of a TaylorScalar (coefficient recurrence), Greeks, and the implied volatility by Newton on the
# whole series.
include(joinpath(@__DIR__, "..", "setup.jl"))
using TaylorDiff
using TaylorDiff: value, partials

@test Base.get_extension(FinancialToolbox, :FinancialToolboxTaylorDiffExt) !== nothing

const toll = 1e-14

@testset "normcdf" begin
    # Taylor coefficients: Phi^(k)(x0) / k! = (-1)^(k-1) He_{k-1}(x0) normpdf(x0) / k!
    x0 = 0.3
    normcdf_x = normcdf(TaylorScalar(x0, (1.0, 0.0, 0.0, 0.0, 0.0)))
    He = (1.0, x0, x0^2 - 1, x0^3 - 3 * x0, x0^4 - 6 * x0^2 + 3)
    @test abs(value(normcdf_x) - normcdf(x0)) < toll
    for k = 1:5
        @test abs(partials(normcdf_x)[k] - (-1)^(k - 1) * He[k] * normpdf(x0) / factorial(k)) < toll
    end
end

@testset "Greeks and implied volatility" begin
    (; S0, K, r, T, σ, d) = REFERENCE
    g = closed_form_greeks(true)
    @test abs(TaylorDiff.derivative(s -> blsprice(s, K, r, T, σ, d), S0, Val(1)) - g.delta) < toll
    @test abs(TaylorDiff.derivative(s -> blsprice(s, K, r, T, σ, d), S0, Val(2)) - g.gamma) < toll
    @test abs(TaylorDiff.derivative(p -> blsimpv(S0, K, r, T, p, d), g.price, Val(1)) - 1 / g.vega) < toll
    # the implied volatility of blsprice(S0 series, σ series) is the σ series
    spot_t = TaylorScalar(S0, (1.0, 0.0, 0.0, 0.0, 0.0, 0.0))
    sigma_t = TaylorScalar(σ, (0.05, 0.01, 0.0, -0.002, 0.0, 0.0))
    for FlagIsCall in (true, false)
        vol_t = blsimpv(spot_t, K, r, T, blsprice(spot_t, K, r, T, sigma_t, d, FlagIsCall), d, FlagIsCall)
        @test abs(value(vol_t) - value(sigma_t)) < toll
        @test all(abs.(partials(vol_t) .- partials(sigma_t)) .< toll)
    end
end
