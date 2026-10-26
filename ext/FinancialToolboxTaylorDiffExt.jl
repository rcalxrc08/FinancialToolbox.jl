module FinancialToolboxTaylorDiffExt

using TaylorDiff: TaylorScalar, value, partials
using FinancialToolbox
using FinancialToolbox: blimpv, blimpv_series_newton
import FinancialToolbox: blimpv_impl

constant_value(x::TaylorScalar) = value(x)
constant_value(x) = x
order(::TaylorScalar{T, P}) where {T, P} = P

# normcdf on TaylorScalar (partials are Taylor coefficients) via the recurrence of c = normcdf(a),
# with p = normpdf(a) and q = a p: c' = p a', p' = -q a', so
#   c_k = (1/k) Σ_{j=1}^{k} j a_j p_{k-j},  p_k = -(1/k) Σ_{j=1}^{k} j a_j q_{k-j}
# Defined here because erfc on TaylorScalar from TaylorDiff's SpecialFunctions extension is broken (0.3.5).
function FinancialToolbox.normcdf(a::TaylorScalar{T, P}) where {T, P}
    av = (value(a), partials(a)...)
    c0 = normcdf(av[1])
    p0 = normpdf(av[1])
    c = Vector{typeof(c0)}(undef, P + 1)
    p = Vector{typeof(p0)}(undef, P + 1)
    q = Vector{typeof(av[1] * p0)}(undef, P + 1)
    c[1], p[1], q[1] = c0, p0, av[1] * p0
    for k = 1:P
        c[k+1] = sum(j * av[j+1] * p[k-j+1] for j = 1:k) / k
        p[k+1] = -sum(j * av[j+1] * q[k-j+1] for j = 1:k) / k
        q[k+1] = sum(av[i+1] * p[k-i+1] for i = 0:k)
    end
    return TaylorScalar(c[1], ntuple(i -> c[i+1], Val(P)))
end

# Implied volatility of TaylorScalar: Newton on the whole polynomial, started from the implied volatility of
# the constant terms (see blimpv_series_newton)
function blimpv_impl(::TaylorScalar, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    σ0 = blimpv(constant_value(S0), constant_value(K), constant_value(T), constant_value(price_d), FlagIsCall, xtol, n_iter_max)
    σ = σ0 + zero(S0) + zero(K) + zero(T) + zero(price_d)
    return blimpv_series_newton(σ, S0, K, T, price_d, FlagIsCall, order(σ))
end

end
