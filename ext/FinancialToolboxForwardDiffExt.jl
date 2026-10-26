module FinancialToolboxForwardDiffExt

using ForwardDiff
using FinancialToolbox: blimpv, blprice_diff_impl, blvega_impl
import FinancialToolbox: blimpv_impl

value_fwd_diff(x::ForwardDiff.Dual) = x.value
value_fwd_diff(x) = x

function blimpv_impl(::ForwardDiff.Dual, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    S0_r = value_fwd_diff(S0)
    K_r = value_fwd_diff(K)
    T_r = value_fwd_diff(T)
    p_r = value_fwd_diff(price_d)
    σ = blimpv(S0_r, K_r, T_r, p_r, FlagIsCall, xtol, n_iter_max)
    der_ = blprice_diff_impl(S0, K, T, σ, price_d, FlagIsCall) / blvega_impl(S0_r, K_r, T_r, σ)
    return σ + der_
end

end
