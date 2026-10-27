module FinancialToolboxTaylorSeriesExt

using TaylorSeries
using FinancialToolbox
using FinancialToolbox: blimpv, blimpv_series_newton
import FinancialToolbox: blimpv_impl, blcheck_impl

import SpecialFunctions: erfc
using IrrationalConstants: sqrtπ

# erfc on Taylor1 and TaylorN (normcdf wraps it) via a coefficient recurrence. erfc(a)' = g a', so
# its coefficients follow k c_k = Σ_{j=1}^{k} j a_j g_{k-j}. For TaylorN, coefficient k is the homogeneous
# part of degree k and the same identity holds by Euler's theorem (apply Σᵢ xᵢ ∂ᵢ).
# Works for any coefficient type (Int, BigFloat, Taylor1, TaylorN, ...).
const TaylorType = Union{Taylor1,TaylorN}
constant_value(a::Taylor1) = a[0]
constant_value(a::TaylorN) = a[0][1]
constant_value(x) = x
constant_coefficient(::Taylor1, v) = v
constant_coefficient(::TaylorN, v) = HomogeneousPolynomial([v], 0)
# The order is the number of coefficients - 1 (get_order up to TaylorSeries 0.20, order from 0.23)
series_order(a::TaylorType) = length(a.coeffs) - 1
series(a::Taylor1, coeffs) = Taylor1(coeffs, series_order(a))
series(a::TaylorN, coeffs) = TaylorN(coeffs, series_order(a))

# Coefficient k of a product: Σ_{j=jmin}^{k} a_j b_{k-j} (vectors are 1-based)
convolution(a, b, k, jmin) = sum(a[j+1] * b[k-j+1] for j = jmin:k)
# Homogeneous polynomials: accumulate in place into a single polynomial of degree k
function convolution(a::AbstractVector{<:HomogeneousPolynomial}, b::AbstractVector{<:HomogeneousPolynomial}, k, jmin)
    acc = HomogeneousPolynomial(zero(a[1][1] * b[1][1]), k)
    for j = jmin:k
        TaylorSeries.mul!(acc, a[j+1], b[k-j+1])
    end
    return acc
end
# x * num / den with integer num, den (exact for any coefficient type)
scale(x, num, den) = x * num / den
scale(x::HomogeneousPolynomial, num, den) = (x.coeffs.=x.coeffs .* num ./ den; x)

# erfc(a)' = g a' with g = -2 / √π exp(-a²), and g' = -2 a g a'
function erfc(a::TaylorType)
    n = series_order(a)
    av = a.coeffs
    ja = [j * av[j+1] for j = 0:n] # j a_j
    a0 = constant_value(a)
    c0 = constant_coefficient(a, erfc(a0))
    g0 = constant_coefficient(a, -2 * exp(-a0^2) / sqrtπ)
    c = Vector{typeof(c0)}(undef, n + 1)
    g = Vector{typeof(g0)}(undef, n + 1)
    ag = Vector{typeof(av[1] * g0)}(undef, n + 1)
    c[1], g[1], ag[1] = c0, g0, av[1] * g0
    for k = 1:n
        c[k+1] = scale(convolution(ja, g, k, 1), 1, k)
        g[k+1] = scale(convolution(ja, ag, k, 1), -2, k)
        ag[k+1] = convolution(av, g, k, 0)
    end
    return series(a, c)
end

# Domain checks on the constant terms (comparisons of nested series with zero(type) are not supported)
blcheck_impl(::TaylorType, S0, K, T, σ) = FinancialToolbox.blcheck(constant_value(S0), constant_value(K), constant_value(T), constant_value(σ))

# Implied volatility of Taylor series (Taylor1, TaylorN, nested): Newton on the whole series, started from
# the implied volatility of the constant terms (see blimpv_series_newton)
function blimpv_impl(::TaylorType, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    σ0 = blimpv(constant_value(S0), constant_value(K), constant_value(T), constant_value(price_d), FlagIsCall, xtol, n_iter_max)
    σ = σ0 + zero(S0) + zero(K) + zero(T) + zero(price_d)
    return blimpv_series_newton(σ, S0, K, T, price_d, FlagIsCall, series_order(σ))
end

end
