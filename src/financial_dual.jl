using .DualNumbers
value__d(x) = x.value
value__d(x::Real) = x

function blimpv_impl(::Dual, S0, K, T, price_d, FlagIsCall, xtol, ytol)
    S0_r = value__d(S0)
    K_r = value__d(K)
    T_r = value__d(T)
    p_r = value__d(price_d)
    sigma = blimpv(S0_r, K_r, T_r, p_r, FlagIsCall, xtol, ytol)
    der_ = (price_d - blprice_impl(S0, K, T, sigma, FlagIsCall)) / blvega_impl(S0_r, K_r, T_r, sigma)
    out = sigma + der_
    return out
end
