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
f_zyg(S0) = blsprice(S0, K, r, T, sigma, d);
delta_1 = blsdelta(spot, K, r, T, sigma, d);
delta_v = Zygote.gradient(f_zyg, spot)
@test(abs(delta_v[1] - delta_1) < toll)
price = f_zyg(spot)
f_zyg2(S0) = blsimpv(S0, K, r, T, price, d);
delta_v = Zygote.gradient(f_zyg2, spot)
@test(abs(delta_v[1] + 0.10586634302510232) < toll)
# Gradients with respect to all the inputs: blprice_impl has ChainRulesCore rules with closed form sensitivities
using ForwardDiff, ChainRulesCore
x_price = [100.0, 95.0, 0.02, 1.5, 0.25, 0.01]
for FlagIsCall in (true, false)
    g_price(x) = blsprice(x..., FlagIsCall)
    @test collect(Zygote.gradient((x...) -> blsprice(x..., FlagIsCall), x_price...)) ≈ ForwardDiff.gradient(g_price, x_price)
    g_black(x) = blkprice(x[1:5]..., FlagIsCall)
    @test collect(Zygote.gradient((x...) -> blkprice(x..., FlagIsCall), x_price[1:5]...)) ≈ ForwardDiff.gradient(g_black, x_price)[1:5]
    # frule: directional derivative along (1, 2, 3, 4) of (S0, K, T, σ)
    S0, K_, T_, σ_ = 100.0, 95.0, 1.5, 0.25
    p_fr, dp = ChainRulesCore.frule((NoTangent(), 1.0, 2.0, 3.0, 4.0, NoTangent()), FinancialToolbox.blprice_impl, S0, K_, T_, σ_, FlagIsCall)
    @test p_fr ≈ FinancialToolbox.blprice_impl(S0, K_, T_, σ_, FlagIsCall)
    @test dp ≈ ForwardDiff.derivative(h -> FinancialToolbox.blprice_impl(S0 + h, K_ + 2h, T_ + 3h, σ_ + 4h, FlagIsCall), 0.0)
end
