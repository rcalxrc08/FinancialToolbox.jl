using Test
using FinancialToolbox, Symbolics
toll = 1e-7
@variables S0_s, r_s, d_s, T_s, sigma_s, K_s, price_s
S0 = 100.0;
K = 100.0;
r = 0.02;
T = 1.2;
sigma = 0.2;
d = 0.01;
price = blsprice(S0, K, r, T, sigma, d)
dict_vals = Dict(S0_s => S0, r_s => r, d_s => d, K_s => K, T_s => T, sigma_s => sigma, price_s => price)
price_s_c = blsprice(S0_s, K_s, r_s, T_s, sigma_s, d_s)
price_v = substitute(price_s_c, dict_vals)
@test abs(price - price_v) < toll

vol_s = blsimpv(S0_s, K_s, r_s, T_s, price_s, d_s)
vol_v = substitute(vol_s, dict_vals)
vol = blsimpv(S0, K, r, T, price, d)
@test abs(vol - vol_v) < toll

#Test multiple order derivatives of blsimpv
using HyperDualNumbers
#S0
der_vol_S0 = Symbolics.derivative(vol_s, S0_s, simplify = true);
der_vol_S02 = Symbolics.derivative(der_vol_S0, S0_s, simplify = true);
@show vol_h_S0 = blsimpv(hyper(S0, 1.0, 1.0, 0.0), K, r, T, price, d)
delta = substitute(der_vol_S0, dict_vals)
@show gamma = substitute(der_vol_S02, dict_vals)
@test abs(delta - vol_h_S0.epsilon1) < toll

#K
der_vol_K = Symbolics.derivative(vol_s, K_s, simplify = true);
der_vol_K2 = Symbolics.derivative(der_vol_K, K_s, simplify = true);
vol_h_K = blsimpv(S0, hyper(K, 1.0, 1.0, 0.0), r, T, price, d)
delta_k = substitute(der_vol_K, dict_vals)
gamma_k = substitute(der_vol_K2, dict_vals)
@test abs(delta_k - vol_h_K.epsilon1) < toll
#r
der_vol_r = Symbolics.derivative(vol_s, r_s, simplify = true);
der_vol_r2 = Symbolics.derivative(der_vol_r, r_s, simplify = true);
vol_h_r = blsimpv(S0, K, hyper(r, 1.0, 1.0, 0.0), T, price, d)
delta_r = substitute(der_vol_r, dict_vals)
gamma_r = substitute(der_vol_r2, dict_vals)
@test abs(delta_r - vol_h_r.epsilon1) < toll
#T
der_vol_T = Symbolics.derivative(vol_s, T_s, simplify = true);
der_vol_T2 = Symbolics.derivative(der_vol_T, T_s, simplify = true);
vol_h_T = blsimpv(S0, K, r, hyper(T, 1.0, 1.0, 0.0), price, d)
delta_T = substitute(der_vol_T, dict_vals)
gamma_T = substitute(der_vol_T2, dict_vals)
@test abs(delta_T - vol_h_T.epsilon1) < toll

#Mixed derivative r,T
der_vol_T = Symbolics.derivative(vol_s, T_s, simplify = true);
der_vol_T_r_s = Symbolics.derivative(der_vol_T, r_s, simplify = true);
vol_h_T = blsimpv(S0, K, hyper(r, 0.0, 1.0, 0.0), hyper(T, 1.0, 0.0, 0.0), price, d)
delta_T = substitute(der_vol_T, dict_vals)
gamma_T = substitute(der_vol_T_r_s, dict_vals)
@test abs(delta_T - vol_h_T.epsilon1) < toll

println("Test First Order Passed")

@test abs(gamma - vol_h_S0.epsilon12) < toll
@test abs(gamma_k - vol_h_K.epsilon12) < toll
@test abs(gamma_r - vol_h_r.epsilon12) < toll
@test abs(gamma_T - vol_h_T.epsilon12) < toll
@test abs(gamma_T - vol_h_T.epsilon12) < toll

println("Test Second Order Passed")