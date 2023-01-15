using Test
using FinancialToolbox, Zygote

#Test Parameters
spot = 10.0;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;

toll = 1e-4

#EuropeanCall Option
f(S0) = blsprice(S0, K, r, T, sigma, d);
delta_1 = blsdelta(spot, K, r, T, sigma, d);
delta_v = Zygote.gradient(f, spot)
@test(abs(delta_v[1] - delta_1) < toll)
price = f(spot)
f2(S0) = blsimpv(S0, K, r, T, price, d);
delta_v = Zygote.gradient(f2, spot)
@test(abs(delta_v[1] + 0.10586634302510232) < toll)