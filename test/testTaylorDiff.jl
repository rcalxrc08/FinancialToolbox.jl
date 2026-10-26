using Test
using FinancialToolbox, TaylorDiff
using TaylorDiff: value, partials

@test Base.get_extension(FinancialToolbox, :FinancialToolboxTaylorDiffExt) !== nothing

#Test Parameters
spot = 10.0;
K = 10.0;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;
toll = 1e-14

#normcdf: Taylor coefficients are Phi^(k)(x0) / k! = (-1)^(k-1) He_{k-1}(x0) normpdf(x0) / k!
x0 = 0.3
normcdf_x = normcdf(TaylorScalar(x0, (1.0, 0.0, 0.0, 0.0, 0.0)))
He = (1.0, x0, x0^2 - 1, x0^3 - 3 * x0, x0^4 - 6 * x0^2 + 3)
@test abs(value(normcdf_x) - normcdf(x0)) < toll
for k = 1:5
    @test abs(partials(normcdf_x)[k] - (-1)^(k - 1) * He[k] * normpdf(x0) / factorial(k)) < toll
end

#Greeks of blsprice
price_spot(s) = blsprice(s, K, r, T, sigma, d)
@test abs(TaylorDiff.derivative(price_spot, spot, Val(1)) - blsdelta(spot, K, r, T, sigma, d)) < toll
@test abs(TaylorDiff.derivative(price_spot, spot, Val(2)) - blsgamma(spot, K, r, T, sigma, d)) < toll

#blsimpv: derivative w.r.t. the price is 1 / vega
price = blsprice(spot, K, r, T, sigma, d)
@test abs(TaylorDiff.derivative(p -> blsimpv(spot, K, r, T, p, d), price, Val(1)) - 1 / blsvega(spot, K, r, T, sigma, d)) < toll

#blsimpv: the implied volatility of blsprice(S0 series, sigma series) is the sigma series
for FlagIsCall in (true, false)
    spot_t = TaylorScalar(spot, (1.0, 0.0, 0.0, 0.0, 0.0, 0.0))
    sigma_t = TaylorScalar(sigma, (0.05, 0.01, 0.0, -0.002, 0.0, 0.0))
    price_t = blsprice(spot_t, K, r, T, sigma_t, d, FlagIsCall)
    vol_t = blsimpv(spot_t, K, r, T, price_t, d, FlagIsCall)
    @test abs(value(vol_t) - value(sigma_t)) < toll
    @test all(abs.(partials(vol_t) .- partials(sigma_t)) .< toll)
end
