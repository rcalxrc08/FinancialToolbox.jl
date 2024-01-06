using .ForwardDiff
value__d(x::ForwardDiff.Dual) = x.value
value__d(x) = x

function blimpv_impl(::ForwardDiff.Dual, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    S0_r = value__d(S0)
    K_r = value__d(K)
    T_r = value__d(T)
    p_r = value__d(price_d)
    σ = blimpv(S0_r, K_r, T_r, p_r, FlagIsCall, xtol, n_iter_max)
    der_ = blprice_diff_impl(S0, K, T, σ, price_d, FlagIsCall) / blvega_impl(S0_r, K_r, T_r, σ)
    return σ + der_
end