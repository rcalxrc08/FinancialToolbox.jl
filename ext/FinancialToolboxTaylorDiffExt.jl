module FinancialToolboxTaylorDiffExt

using TaylorDiff: TaylorScalar, value
using FinancialToolbox
using FinancialToolbox: blimpv, blimpv_series_newton
import FinancialToolbox: blimpv_impl

# normcdf needs no method here: TaylorDiff's own erfc (its SpecialFunctions extension, fixed in 0.3.6) is exact to the
# last bits, keeps Float32, does not allocate and runs in GPU kernels; it was 1.1-2.7 times faster than the
# coefficient recurrence this extension had up to TaylorDiff 0.3.5.

constant_value(x::TaylorScalar) = value(x)
constant_value(x) = x
order(::TaylorScalar{T, P}) where {T, P} = P

# Implied volatility of TaylorScalar: Newton on the whole polynomial, started from the implied volatility of
# the constant terms (see blimpv_series_newton)
function blimpv_impl(::Type{<:TaylorScalar}, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    σ0 = blimpv(constant_value(S0), constant_value(K), constant_value(T), constant_value(price_d), FlagIsCall, xtol, n_iter_max)
    σ = σ0 + zero(S0) + zero(K) + zero(T) + zero(price_d)
    return blimpv_series_newton(σ, S0, K, T, price_d, FlagIsCall, order(σ))
end

end
