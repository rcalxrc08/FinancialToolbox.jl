using .ReverseDiff
# blsimpv_impl(x::ReverseDiff.TrackedReal,S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol) = ReverseDiff.track(blsimpv_impl,x,S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
# ReverseDiff.@grad function blsimpv_impl(x,S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
# S0_r=ReverseDiff.value(S0)
# K_r=ReverseDiff.value(K)
# r_r=ReverseDiff.value(r)
# T_r=ReverseDiff.value(T)
# p_r=ReverseDiff.value(price_d)
# d_r=ReverseDiff.value(d)
# sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r, FlagIsCall, xtol, ytol)
# function update_pullback(slice)
# inputs = [S0_r, K_r, r_r, T_r, sigma, d_r];
# @views fwd_grad=ReverseDiff.gradient(x -> blsprice(x[1], x[2], x[3], x[4], x[5], x[6], FlagIsCall), inputs)
# @views der_S0 = fwd_grad[1]
# @views der_K = fwd_grad[2]
# @views der_r = fwd_grad[3]
# @views der_T = fwd_grad[4]
# @views der_d = fwd_grad[6]
# @views slice_mod = -1 / fwd_grad[5]
# return 0, slice_mod * der_S0, slice_mod * der_K, slice_mod * der_r, slice_mod * der_T, -slice_mod, slice_mod * der_d, 0, 0, 0
# end
# return sigma, update_pullback
# end

function FinancialToolbox.blimpv_impl(::ReverseDiff.TrackedReal, S0, K, T, price_d, FlagIsCall, xtol, ytol)
    S0_r = ReverseDiff.value(S0)
    K_r = ReverseDiff.value(K)
    T_r = ReverseDiff.value(T)
    p_r = ReverseDiff.value(price_d)
    σ = blimpv(S0_r, K_r, T_r, p_r, FlagIsCall, xtol, ytol)
    der_ = (price_d - blprice_impl(S0, K, T, σ, FlagIsCall)) / blvega_impl(S0_r, K_r, T_r, σ)
    out = σ + der_
    return out
end