module FinancialToolboxDualNumbersExt

using DualNumbers
using FinancialToolbox: blimpv, blprice_diff_impl, blvega_impl
import FinancialToolbox: blimpv_impl, normcdf, normpdf, internal_sqrt

# normcdf through erfc and sqrt would promote: DualNumbers takes their derivatives from Calculus.jl, with Float64
# constants (sqrt(pi), 0.5), so Dual{Float32} became Dual{Float64}. The derivative of normcdf is normpdf.
normcdf(x::Dual) = Dual(normcdf(DualNumbers.value(x)), normpdf(DualNumbers.value(x)) * DualNumbers.epsilon(x))
# x^2 of a Dual goes through the generic power of DualNumbers, 6 times slower than x * x: normpdf' = -x normpdf
function normpdf(x::Dual)
    a = DualNumbers.value(x)
    φ = normpdf(a)
    return Dual(φ, -a * φ * DualNumbers.epsilon(x))
end
function internal_sqrt(x::Dual)
    root = sqrt(DualNumbers.value(x))
    return Dual(root, DualNumbers.epsilon(x) / (2 * root))
end

value_dual(x::Dual) = x.value
value_dual(x) = x

function blimpv_impl(::Type{<:Dual}, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    S0_r = value_dual(S0)
    K_r = value_dual(K)
    T_r = value_dual(T)
    p_r = value_dual(price_d)
    σ = blimpv(S0_r, K_r, T_r, p_r, FlagIsCall, xtol, n_iter_max)
    der_ = blprice_diff_impl(S0, K, T, σ, price_d, FlagIsCall) / blvega_impl(S0_r, K_r, T_r, σ)
    return σ + der_
end

end
