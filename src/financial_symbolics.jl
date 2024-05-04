using .Symbolics

function blcheck_impl(::num0, S0::num1, K::num2, T::num4, σ::num5) where {num0 <: Num, num1, num2, num4, num5}
    return
end

@register_symbolic blimpv(S0, K, T, Price, FlagIsCall::Bool, xtol::Float64, n_iter_max::Int64)

function blvega_impl_registered(S0, K, T, σ)
    return blvega_impl(S0, K, T, σ)
end

function Symbolics.derivative(::typeof(blvega_impl_registered), ::NTuple{4, Any}, ::Any)
    return 0
end
function finalize_derivative_fwd(S0, K, T, σ, der_fwd)
    vega = blvega_impl_registered(S0, K, T, σ)
    return der_fwd / vega
end
# function finalize_derivative_fwd(vega, price_diff, target_var, original_var)
#     der_fwd = Symbolics.derivative(price_diff, target_var)
#     der_fwd = substitute(der_fwd, Dict(target_var => original_var))
#     return der_fwd / vega
# end
function bldelta(S0, K, T, σ, FlagIsCall)
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = log(S0_K) / sigma_sqrtT + sigma_sqrtT / FinancialToolbox.two_internal
    iscall = ifelse(FlagIsCall, FinancialToolbox.one_internal, FinancialToolbox.minus_one_internal)
    Δ = normcdf(iscall * d1) * iscall
    return Δ
end
#TODO: implement derivatives
function Symbolics.derivative(::typeof(blimpv), args::NTuple{7, Any}, ::Val{1})
    S0, K, T, price_d, FlagIsCall, xtol, n_iter_max = args
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    @variables new_S0
    price_diff = -blprice_impl(new_S0, K, T, σ, FlagIsCall)
    der_fwd = Symbolics.derivative(price_diff, new_S0)
    der_fwd = substitute(der_fwd, Dict(new_S0 => S0))
    #der_fwd = bldelta(S0, K, r, T, σ, d, FlagIsCall)
    return finalize_derivative_fwd(S0, K, T, σ, der_fwd)
end
function Symbolics.derivative(::typeof(blimpv), args::NTuple{7, Any}, ::Val{2})
    S0, K, T, price_d, FlagIsCall, xtol, n_iter_max = args
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    @variables new_K
    price_diff = -blprice_impl(S0, new_K, T, σ, FlagIsCall)
    der_fwd = Symbolics.derivative(price_diff, new_K)
    der_fwd = substitute(der_fwd, Dict(new_K => K))
    #der_fwd = bldelta(S0, K, r, T, σ, d, FlagIsCall)
    return finalize_derivative_fwd(S0, K, T, σ, der_fwd)
end
function Symbolics.derivative(::typeof(blimpv), args::NTuple{7, Any}, ::Val{3})
    S0, K, T, price_d, FlagIsCall, xtol, n_iter_max = args
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    @variables new_T
    price_diff = -blprice_impl(S0, K, new_T, σ, FlagIsCall)
    der_fwd = Symbolics.derivative(price_diff, new_T)
    der_fwd = substitute(der_fwd, Dict(new_T => T))
    #der_fwd = bldelta(S0, K, r, T, σ, d, FlagIsCall)
    return finalize_derivative_fwd(S0, K, T, σ, der_fwd)
end
function Symbolics.derivative(::typeof(blimpv), args::NTuple{7, Any}, ::Val{4})
    S0, K, T, price_d, FlagIsCall, xtol, n_iter_max = args
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    vega = blvega_impl_registered(S0, K, T, σ)
    return inv(vega)
end
function Symbolics.derivative(::typeof(blimpv), ::NTuple{7, Any}, ::Any)
    return 0
end