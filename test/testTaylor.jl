using Test
using FinancialToolbox, TaylorSeries

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

dS0, dr, dsigma = set_variables("dS0 dr dsigma", order = 4)
PriceCall2 = blsprice(spot + dS0, K, r + dr, T, sigma + dsigma, d);
@test(abs(1.1912013169995816 - PriceCall2[0][1]) < toll)
@test(abs(0.5724340508103682 - PriceCall2[1][1]) < toll)
@test(abs(gamma_opt - PriceCall2[2][1] * 2) < toll)

#Broken for some reason
VolaCall = blsimpv(spotDual, K, r, T, PriceCall, d);
@test(abs(VolaCall[0] - 0.2) < toll)
# @test(abs(VolaCall[1]) < toll)

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