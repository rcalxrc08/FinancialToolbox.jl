using Test
using FinancialToolbox, TaylorSeries

#Test Parameters
testToll = 1e-14;

spot = 10.0;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;
spotDual=taylor_expand(identity,spot,order=22)

toll = 1e-6

#EuropeanCall Option
PriceCall = blsprice(spotDual, K, r, T, sigma, d);
@test(abs(1.1912013169995816-PriceCall[0])<toll)
@test(abs(0.5724340508103682-PriceCall[1])<toll)


dS0, dr, dsigma = set_variables("dS0 dr dsigma", order=4)
PriceCall2 = blsprice(spot+dS0, K, r+dr, T, sigma+dsigma, d);
@test(abs(1.1912013169995816-PriceCall2[0])<toll)
@test(abs(0.5724340508103682-PriceCall2[1])<toll)