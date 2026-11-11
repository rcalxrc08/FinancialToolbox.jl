# TaylorSeries: prices and implied volatilities of Taylor1 (Float64, BigFloat, nested) and TaylorN, normcdf of a series.
include(joinpath(@__DIR__, "..", "setup.jl"))
using TaylorSeries

# TaylorSeries 0.23 renamed set_variables to variables!
taylorn_variables(names; order) = isdefined(TaylorSeries, :variables!) ? TaylorSeries.variables!(names; order = order) : TaylorSeries.set_variables(names; order = order)

const x_n, y_n = taylorn_variables("x y", order = 5)

@testset "Prices" begin
    (; S0, K, r, T, σ, d) = REFERENCE
    toll = 1e-12
    g = closed_form_greeks(true)
    price = blsprice(S0 + Taylor1(Float64, 4), K, r, T, σ, d)
    @test abs(price[0] - MATLAB.call.price) < toll
    @test abs(price[1] - g.delta) < toll
    @test abs(2 * price[2] - g.gamma) < toll
    # TaylorN in S0 and σ: price, delta, gamma, vega, vanna
    price = blsprice(S0 + x_n, K, r, T, σ + y_n, d)
    @test abs(price[0][1] - MATLAB.call.price) < toll
    @test abs(price[1][1] - g.delta) < toll
    @test abs(price[1][2] - g.vega) < toll
    @test abs(2 * price[2][1] - g.gamma) < toll
    @test abs(price[2][2] - g.vanna) < toll
end

@testset "normcdf" begin
    # coefficients of Taylor1: Phi^(k)(x0) / k! = (-1)^(k-1) He_{k-1}(x0) normpdf(x0) / k!
    x0 = 0.3
    normcdf_x = normcdf(x0 + Taylor1(Float64, 5))
    He = (1.0, x0, x0^2 - 1, x0^3 - 3 * x0, x0^4 - 6 * x0^2 + 3)
    @test abs(normcdf_x[0] - normcdf(x0)) < 1e-15
    for k = 1:5
        @test abs(normcdf_x[k] - (-1)^(k - 1) * He[k] * normpdf(x0) / factorial(k)) < 1e-15
    end
    # Int, BigFloat and nested Taylor1 coefficients
    @test normcdf(Taylor1([0, 1], 4)) ≈ normcdf(Taylor1([0.0, 1.0], 4))
    normcdf_big = normcdf(big(x0) + Taylor1(BigFloat, 5))
    @test eltype(normcdf_big.coeffs) == BigFloat
    @test abs(normcdf_big[3] - normcdf_x[3]) < 1e-15
    # mixed derivative of normcdf(x * y) at (0.5, 0.8): normpdf(x * y) * (1 - (x * y)^2)
    x_nested = Taylor1([Taylor1([0.5, 1.0], 1), zero(Taylor1([0.5], 1))], 1)
    y_nested = Taylor1([Taylor1([0.8], 1), one(Taylor1([0.8], 1))], 1)
    @test abs(normcdf(x_nested * y_nested)[1][1] - normpdf(0.4) * (1 - 0.4^2)) < 1e-15
    # TaylorN: the univariate series evaluated on the (multivariate) argument
    for u in (x_n + 2 * y_n, sin(x_n) * y_n + x_n^2)
        difference = normcdf(x0 + u) - evaluate(normcdf_x, u)
        @test all(k -> maximum(abs, difference[k].coeffs) < 1e-15, 0:5)
    end
    @test normcdf(x0 + x_n)[0][1] == normcdf(x0)
end

# the implied volatility of blsprice(..., σ series) is the σ series
@testset "Implied volatility" begin
    (; S0, K, r, T, d) = REFERENCE
    sigma_t = 0.2 + 0.05 * sin(Taylor1(Float64, 10)) + 0.01 * Taylor1(Float64, 10)^2
    for spot_t in (S0, S0 + Taylor1(Float64, 10)), FlagIsCall in (true, false)
        price_t = blsprice(spot_t, K, r, T, sigma_t, d, FlagIsCall)
        @test all(abs.((blsimpv(spot_t, K, r, T, price_t, d, FlagIsCall) - sigma_t).coeffs) .< 1e-14)
    end
    # constant σ: the series of the implied volatility is constant
    spot_t = S0 + Taylor1(Float64, 6)
    vol = blsimpv(spot_t, K, r, T, blsprice(spot_t, K, r, T, 0.2, d), d)
    @test abs(vol[0] - 0.2) < 1e-14
    @test all(abs.(vol.coeffs[2:end]) .< 1e-10)
    # all inputs in BigFloat recover high orders
    spot_big = big(S0) + Taylor1(BigFloat, 22)
    sigma_big = big"0.2" + Taylor1(BigFloat, 22)
    price_big = blsprice(spot_big, big(K), big"0.02", big(T), sigma_big, big"0.01")
    @test all(abs.((blsimpv(spot_big, big(K), big"0.02", big(T), price_big, big"0.01", true, 1e-40, 4) - sigma_big).coeffs) .< 1e-50)
    # nested Taylor1
    inner_t = Taylor1([0.0, 1.0], 2)
    spot_nested = Taylor1([S0 + inner_t, one(inner_t)], 2)
    sigma_nested = Taylor1([0.2 + 0.1 * inner_t, 0.05 * one(inner_t)], 2)
    vol_nested = blsimpv(spot_nested, K, r, T, blsprice(spot_nested, K, r, T, sigma_nested, d), d)
    @test all(c -> maximum(abs, c.coeffs) < 1e-14, (vol_nested - sigma_nested).coeffs)
    # TaylorN
    sigma_n = 0.2 + 0.05 * x_n + 0.01 * x_n * y_n
    vol_n = blsimpv(S0 + x_n, K, r, T, blsprice(S0 + x_n, K, r, T, sigma_n, d), d) - sigma_n
    @test all(k -> maximum(abs, vol_n[k].coeffs) < 1e-14, 0:5)
end
