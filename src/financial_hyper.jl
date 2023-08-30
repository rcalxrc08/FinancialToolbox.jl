using .HyperDualNumbers

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
    sigma_tmp -= Hyper(0, 0, 0, HyperDualNumbers.eps1eps2(sigma_tmp))
    sigma_tmp += (price_d - blsprice(S0, K, r, T, sigma_tmp, d, FlagIsCall)) / vega
    return sigma_tmp
end
