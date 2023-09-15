using .HyperDualNumbers

function blimpv_impl(::Hyper, S0, K, T, price_d, FlagIsCall, xtol, ytol)
    S0_r = HyperDualNumbers.value(S0)
    K_r = HyperDualNumbers.value(K)
    T_r = HyperDualNumbers.value(T)
    pr_r = HyperDualNumbers.value(price_d)
    sigma = blimpv(S0_r, K_r, T_r, pr_r, FlagIsCall, xtol, ytol)
    vega = blvega_impl(S0_r, K_r, T_r, sigma)
    sigma_tmp = sigma + (price_d - blprice_impl(S0, K, T, sigma, FlagIsCall)) / vega
    sigma_tmp -= Hyper(0, 0, 0, HyperDualNumbers.eps1eps2(sigma_tmp))
    sigma_tmp += (price_d - blprice_impl(S0, K, T, sigma_tmp, FlagIsCall)) / vega
    return sigma_tmp
end
