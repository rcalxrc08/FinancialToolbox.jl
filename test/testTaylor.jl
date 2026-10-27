using Test
using FinancialToolbox, TaylorSeries

# TaylorSeries 0.23 renamed set_variables to variables!
taylorn_variables(names; order) = isdefined(TaylorSeries, :variables!) ? TaylorSeries.variables!(names; order = order) : TaylorSeries.set_variables(names; order = order)

#Test Parameters
spot = 10.0;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;
spotDual = taylor_expand(identity, spot, order = 22)

toll = 1e-4

#EuropeanCall Option
PriceCall = blsprice(spotDual, K, r, T, sigma, d);
@test(abs(1.1912013169995816 - PriceCall[0]) < toll)
@test(abs(0.5724340508103682 - PriceCall[1]) < toll)
gamma_opt = blsgamma(spot, K, r, T, sigma, d);
@test(abs(gamma_opt - PriceCall[2] * 2) < toll)

dS0, dr, dsigma = taylorn_variables("dS0 dr dsigma", order = 4)
PriceCall2 = blsprice(spot + dS0, K, r + dr, T, sigma + dsigma, d);
@test(abs(1.1912013169995816 - PriceCall2[0][1]) < toll)
@test(abs(0.5724340508103682 - PriceCall2[1][1]) < toll)
@test(abs(gamma_opt - PriceCall2[2][1] * 2) < toll)

VolaCall = blsimpv(spotDual, K, r, T, PriceCall, d);
@test(abs(VolaCall[0] - 0.2) < toll)
@test(abs(VolaCall[1]) < toll)

# #EuropeanCall Option
sigma_dual = taylor_expand(identity, sigma, order = 22)
PriceCall3 = blsprice(spotDual, K, r, T, sigma_dual, d);
VolaCall3 = blsimpv(spotDual, K, r, T, PriceCall3, d);
@test(abs(VolaCall3[0] - sigma_dual[0]) < toll)
@test(abs(VolaCall3[1] - sigma_dual[1]) < toll)
@test(abs(VolaCall3[2] - sigma_dual[2]) < toll)
@test(abs(VolaCall3[3] - sigma_dual[3]) < toll)

sigma_dual_new = deepcopy(PriceCall3)
sigma_dual_new[0] = sigma
PriceCall3 = blsprice(spotDual, K, r, T, sigma_dual_new, d);
VolaCall3 = blsimpv(spotDual, K, r, T, PriceCall3, d);
@show VolaCall3
@show sigma_dual_new
@test(abs(VolaCall3[0] - sigma_dual_new[0]) < toll)
@show @test(abs(VolaCall3[1] - sigma_dual_new[1]) < toll)
@test(abs(VolaCall3[2] - sigma_dual_new[2]) < toll)
@test(abs(VolaCall3[3] - sigma_dual_new[3]) < toll)

sigma_dual_new = deepcopy(PriceCall3)
sigma_dual_new[0] = sigma
PriceCall3 = blsprice(spot, K, r, T, sigma_dual_new, d);
VolaCall3 = blsimpv(spot, K, r, T, PriceCall3, d);

@test(abs(VolaCall3[0] - sigma_dual_new[0]) < toll)
@test(abs(VolaCall3[1] - sigma_dual_new[1]) < toll)
@test(abs(VolaCall3[2] - sigma_dual_new[2]) < toll)
@test(abs(VolaCall3[3] - sigma_dual_new[3]) < toll)

#normcdf on Taylor1: coefficients are Phi^(k)(x0) / k! = (-1)^(k-1) He_{k-1}(x0) normpdf(x0) / k!
x0 = 0.3
normcdf_x = normcdf(x0 + Taylor1(Float64, 5))
He = (1.0, x0, x0^2 - 1, x0^3 - 3 * x0, x0^4 - 6 * x0^2 + 3)
@test(abs(normcdf_x[0] - normcdf(x0)) < 1e-15)
for k = 1:5
    @test(abs(normcdf_x[k] - (-1)^(k - 1) * He[k] * normpdf(x0) / factorial(k)) < 1e-15)
end
#normcdf on Taylor1 with Int, BigFloat and nested Taylor1 coefficients
@test(normcdf(Taylor1([0, 1], 4)) ≈ normcdf(Taylor1([0.0, 1.0], 4)))
normcdf_big = normcdf(big(x0) + Taylor1(BigFloat, 5))
@test(eltype(normcdf_big.coeffs) == BigFloat)
@test(abs(normcdf_big[3] - normcdf_x[3]) < 1e-15)
#mixed derivative of normcdf(x * y) at (0.5, 0.8): normpdf(x * y) * (1 - (x * y)^2)
x_nested = Taylor1([Taylor1([0.5, 1.0], 1), zero(Taylor1([0.5], 1))], 1)
y_nested = Taylor1([Taylor1([0.8], 1), one(Taylor1([0.8], 1))], 1)
@test(abs(normcdf(x_nested * y_nested)[1][1] - normpdf(0.4) * (1 - 0.4^2)) < 1e-15)

#normcdf on TaylorN: compare with the univariate series evaluated on the (multivariate) argument
x_n, y_n = taylorn_variables("x y", order = 5)
normcdf_n = normcdf(x0 + x_n + 2 * y_n)
normcdf_n_ref = evaluate(normcdf(x0 + Taylor1(Float64, 5)), x_n + 2 * y_n)
@test(all(k -> maximum(abs, (normcdf_n - normcdf_n_ref)[k].coeffs) < 1e-15, 0:5))
u_n = sin(x_n) * y_n + x_n^2
normcdf_nl = normcdf(x0 + u_n)
normcdf_nl_ref = evaluate(normcdf(x0 + Taylor1(Float64, 5)), u_n)
@test(all(k -> maximum(abs, (normcdf_nl - normcdf_nl_ref)[k].coeffs) < 1e-15, 0:5))
@test(normcdf(x0 + x_n)[0][1] == normcdf(x0))

#blsimpv on Taylor series: the implied volatility series of blsprice(..., σ series) is σ
sigma_t = 0.2 + 0.05 * sin(Taylor1(Float64, 10)) + 0.01 * Taylor1(Float64, 10)^2
spot_t = spot + Taylor1(Float64, 10)
for FlagIsCall in (true, false)
    price_t = blsprice(spot_t, K, r, T, sigma_t, d, FlagIsCall)
    @test(all(abs.((blsimpv(spot_t, K, r, T, price_t, d, FlagIsCall) - sigma_t).coeffs) .< 1e-14))
end
#all inputs in BigFloat recover high orders
spot_big = big(spot) + Taylor1(BigFloat, 22)
sigma_big = big"0.2" + Taylor1(BigFloat, 22)
price_big = blsprice(spot_big, big(K), big"0.02", big(T), sigma_big, big"0.01")
@test(all(abs.((blsimpv(spot_big, big(K), big"0.02", big(T), price_big, big"0.01", true, 1e-40, 4) - sigma_big).coeffs) .< 1e-50))
#nested Taylor1
inner_t = Taylor1([0.0, 1.0], 2)
spot_nested = Taylor1([spot + inner_t, one(inner_t)], 2)
sigma_nested = Taylor1([0.2 + 0.1 * inner_t, 0.05 * one(inner_t)], 2)
vol_nested = blsimpv(spot_nested, K, r, T, blsprice(spot_nested, K, r, T, sigma_nested, d), d)
@test(all(c -> maximum(abs, c.coeffs) < 1e-14, (vol_nested - sigma_nested).coeffs))
#TaylorN
sigma_n = 0.2 + 0.05 * x_n + 0.01 * x_n * y_n
vol_n = blsimpv(spot + x_n, K, r, T, blsprice(spot + x_n, K, r, T, sigma_n, d), d) - sigma_n
@test(all(k -> maximum(abs, vol_n[k].coeffs) < 1e-14, 0:5))
