using .HyperDualNumbers

function blimpv_impl(::Hyper, S0, K, T, price_d, FlagIsCall, xtol, ytol)
    S0_r = HyperDualNumbers.value(S0)
    K_r = HyperDualNumbers.value(K)
    T_r = HyperDualNumbers.value(T)
    pr_r = HyperDualNumbers.value(price_d)
    σ = blimpv(S0_r, K_r, T_r, pr_r, FlagIsCall, xtol, ytol)
    vega = blvega_impl(S0_r, K_r, T_r, σ)
    σ_hyper = σ + (price_d - blprice_impl(S0, K, T, σ, FlagIsCall)) / vega
    σ_hyper -= Hyper(0, 0, 0, HyperDualNumbers.eps1eps2(σ_hyper))
    σ_hyper += (price_d - blprice_impl(S0, K, T, σ_hyper, FlagIsCall)) / vega
    return σ_hyper
end
