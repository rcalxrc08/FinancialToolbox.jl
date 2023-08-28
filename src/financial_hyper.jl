using .HyperDualNumbers

function blsvolga(S0, K, r, T, σ, d)
    d1 = compute_d1(S0, K, r, T, σ, d)
    d2 = d1 - σ * sqrt(T)
    vega = blsvega(S0, K, r, T, σ, d)
    return vega * d1 * d2 / σ
end

function blsimpv_impl(::Hyper, S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
    S0_r = HyperDualNumbers.value(S0)
    K_r = HyperDualNumbers.value(K)
    r_r = HyperDualNumbers.value(r)
    T_r = HyperDualNumbers.value(T)
    pr_r = HyperDualNumbers.value(price_d)
    d_r = HyperDualNumbers.value(d)
    sigma = blsimpv(S0_r, K_r, r_r, T_r, pr_r, d_r, FlagIsCall, xtol, ytol)
    vega = blsvega(S0_r, K_r, r_r, T_r, sigma, d_r)
    sigma_tmp = sigma + (price_d - blsprice(S0, K, r, T, sigma, d, FlagIsCall)) / vega
    # der_1 = cur_diff.epsilon1 / vega
    # der_2 = cur_diff.epsilon2 / vega
    # sigma_tmp = sigma + (sigma_tmp - Hyper(0, 0, 0, HyperDualNumbers.eps1eps2(sigma_tmp)))
    sigma_tmp -= Hyper(0, 0, 0, HyperDualNumbers.eps1eps2(sigma_tmp))
    sigma_tmp += (price_d - blsprice(S0, K, r, T, sigma_tmp, d, FlagIsCall)) / vega
    return sigma_tmp
end

# function blsimpv_impl(zero_typed::Hyper,S0, K, r, T, price_d,d,FlagIsCall,xtol, ytol)
# 	f_(x) = price_d-blsprice(S0, K, r, T, x, d, FlagIsCall)
# 	σ = FinancialToolbox.brentMethod(x->f_(hyper(x)).value, 0.001, 1.2, xtol, ytol)
# 	σ_der1 = FinancialToolbox.brentMethod(x->f_( hyper(σ,x,0.0,0.0)).epsilon1, -2.0, 1.2, 1e-15, 1e-15)
# 	σ_der2 = FinancialToolbox.brentMethod(x->f_( hyper(σ,σ_der1,x,0.0)).epsilon2, -2.0, 1.2, 1e-15, 1e-15)
# 	σ_der12 = FinancialToolbox.brentMethod(x->f_( hyper(σ,σ_der1,σ_der2,x)).epsilon12, -2.0, 1.2, 1e-15, 1e-15)
# 	return hyper(σ,σ_der1,σ_der2,σ_der12);
# end