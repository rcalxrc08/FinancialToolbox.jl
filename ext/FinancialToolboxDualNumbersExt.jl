module FinancialToolboxDualNumbersExt

using DualNumbers
using FinancialToolbox: blimpv, blprice_diff_impl, blvega_impl
import FinancialToolbox: blimpv_impl

value_dual(x::Dual) = x.value
value_dual(x) = x

function blimpv_impl(::Dual, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    S0_r = value_dual(S0)
    K_r = value_dual(K)
    T_r = value_dual(T)
    p_r = value_dual(price_d)
    σ = blimpv(S0_r, K_r, T_r, p_r, FlagIsCall, xtol, n_iter_max)
    der_ = blprice_diff_impl(S0, K, T, σ, price_d, FlagIsCall) / blvega_impl(S0_r, K_r, T_r, σ)
    return σ + der_
end

end
