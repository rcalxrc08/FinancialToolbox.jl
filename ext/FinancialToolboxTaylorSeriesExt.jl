module FinancialToolboxTaylorSeriesExt

using TaylorSeries
using FinancialToolbox
using FinancialToolbox: blimpv, blimpv_series_newton
import FinancialToolbox: blimpv_impl, domain_value

import SpecialFunctions: erfc
using FinancialToolbox: square, twoinvsqrtπ

# erfc on Taylor1 and TaylorN (normcdf wraps it). With g = -2 / √π exp(-a²) (twoinvsqrtπ, a constant of the
# package), erfc(a)' = g a', so its coefficients follow k c_k = Σ_{j=1}^{k} j a_j g_{k-j}. For TaylorN, coefficient k
# is the homogeneous part of degree k and the same identity holds by Euler's theorem (apply Σᵢ xᵢ ∂ᵢ).
const TaylorType = Union{Taylor1, TaylorN}
# The square of a TaylorN by its own power, 1.5 times faster than the product (see FinancialToolbox.square)
FinancialToolbox.square(x::TaylorN) = x^2
# Taylor1 with scalar coefficients (not series themselves), which has a dedicated loop below
const ScalarTaylor1 = Taylor1{<:Union{Real, Complex}}
constant_value(a::Taylor1) = a[0]
constant_value(a::TaylorN) = a[0][1]
constant_value(x) = x
constant_coefficient(::Taylor1, v) = v
# The coefficients of a TaylorN are built from its own polynomials, never from orders: a polynomial built from an order is
# in the global default JetSpace, which since TaylorSeries 0.23 need not be the space of the input (#91).
function constant_coefficient(a::TaylorN, v)
    c = zero(a[0]) * zero(v)
    c.coeffs[1] = v
    return c
end
# The order is the number of coefficients - 1 (get_order up to TaylorSeries 0.20, order from 0.23)
series_order(a::TaylorType) = length(a.coeffs) - 1
series(a::Taylor1, coeffs) = Taylor1(coeffs, series_order(a))
series(a::TaylorN, coeffs) = TaylorN(coeffs, series_order(a))

# Taylor1 with scalar coefficients (Float64, BigFloat, Int, Complex, dual numbers, ...): one pass, no intermediate series.
# g' = -2 a a' g gives k g_k = -Σ_{j=1}^{k} j s_j g_{k-j} with s = a², whose coefficients are symmetric sums.
function erfc(a::ScalarTaylor1)
    n = series_order(a)
    av = a.coeffs
    a0 = av[1]
    c0 = erfc(a0)
    g0 = -(twoinvsqrtπ * exp(-square(a0)))
    R = promote_type(typeof(c0), typeof(g0))
    c = Vector{R}(undef, n + 1)
    g = Vector{R}(undef, n + 1)
    s = Vector{R}(undef, n + 1) # s[k+1] = k (a²)_k
    c[1], g[1] = c0, g0
    @inbounds for k = 1:n
        sk = zero(R)
        for i = 0:((k-1)>>1)
            sk = muladd(av[i+1], av[k-i+1], sk)
        end
        sk += sk
        if iseven(k)
            sk = muladd(av[(k>>1)+1], av[(k>>1)+1], sk)
        end
        s[k+1] = k * sk
        gk = zero(R)
        ck = zero(R)
        for j = 1:k
            gk = muladd(s[j+1], g[k-j+1], gk)
            ck = muladd(j * av[j+1], g[k-j+1], ck)
        end
        g[k+1] = -gk / k
        c[k+1] = ck / k
    end
    return Taylor1(c, n)
end

# General method (TaylorN, nested series): the same recurrences on the coefficients, which are homogeneous
# polynomials for TaylorN and series for nested series. Every product and sum of coefficients allocates a new series
# here, which dominates the time: @inbounds, loops with muladd instead of the generator sums, and folding j into
# convolution instead of the vector ja were measured (#86, #87) and gained nothing (folding j allocates n² series
# instead of n), so they are left out.
# Coefficient k of a², Σ_{i=0}^{k} a_i a_{k-i}, from the symmetric half of the sum (vectors are 1-based)
function square_coefficient(a, k)
    acc = sum(a[i+1] * a[k-i+1] for i = 0:((k-1)>>1))
    acc += acc
    return iseven(k) ? acc + a[(k>>1)+1] * a[(k>>1)+1] : acc
end
# Coefficient k of a product without the j = 0 term: Σ_{j=1}^{k} a_j b_{k-j}
convolution(a, b, k) = sum(a[j+1] * b[k-j+1] for j = 1:k)
# Innermost number type of a coefficient: num / den is computed in it, so a Float32 series stays Float32 and a BigFloat
# one gets a BigFloat ratio
scalar_type(::Type{T}) where {T} = T
scalar_type(::Type{<:Union{Taylor1{T}, TaylorN{T}, HomogeneousPolynomial{T}}}) where {T} = scalar_type(T)
ratio(x, num, den) = convert(scalar_type(typeof(x)), num) / den
# x * num / den with integer num, den, as a single product by the ratio: one series less for nested series (a quarter
# faster for Taylor1{TaylorN}), at the cost of one rounding of the ratio
scale(x, num, den) = x * ratio(x, num, den)
# Homogeneous polynomials: accumulated and scaled in place, in a single polynomial of degree k, the zero of the input's
# polynomial of that degree (its JetSpace, #91)
function square_coefficient(a::AbstractVector{<:HomogeneousPolynomial}, k)
    acc = zero(a[k+1])
    for i = 0:((k-1)>>1)
        TaylorSeries.mul!(acc, a[i+1], a[k-i+1])
    end
    acc.coeffs .*= 2
    if iseven(k)
        m = a[(k>>1)+1]
        TaylorSeries.mul!(acc, m, m)
    end
    return acc
end
function convolution(a::AbstractVector{<:HomogeneousPolynomial}, b::AbstractVector{<:HomogeneousPolynomial}, k)
    acc = zero(a[k+1]) * zero(b[1][1])
    for j = 1:k
        TaylorSeries.mul!(acc, a[j+1], b[k-j+1])
    end
    return acc
end
scale(x::HomogeneousPolynomial, num, den) = (x.coeffs .*= ratio(x, num, den); x)

function erfc(a::TaylorType)
    n = series_order(a)
    av = a.coeffs
    ja = [j * av[j+1] for j = 0:n] # j a_j
    a0 = constant_value(a)
    c0 = constant_coefficient(a, erfc(a0))
    g0 = constant_coefficient(a, -(twoinvsqrtπ * exp(-square(a0))))
    c = Vector{typeof(c0)}(undef, n + 1)
    g = Vector{typeof(g0)}(undef, n + 1)
    s = Vector{eltype(av)}(undef, n + 1) # s[k+1] = k (a²)_k
    c[1], g[1], s[1] = c0, g0, zero(av[1])
    for k = 1:n
        s[k+1] = scale(square_coefficient(av, k), k, 1)
        g[k+1] = scale(convolution(s, g, k), -1, k)
        c[k+1] = scale(convolution(ja, g, k), 1, k)
    end
    return series(a, c)
end

# Domain checks on the constant terms, recursively for nested series (comparisons of series with zero are not supported)
domain_value(x::TaylorType) = domain_value(constant_value(x))

# σ0 as a series of the order of the series inputs: the scalar inputs are skipped at compile time (1.7 times faster
# than adding the zeros of all the inputs, for a Taylor1 spot)
lift_to_series(σ, ::Number) = σ
lift_to_series(σ, x::TaylorType) = σ + zero(x)

# Implied volatility of Taylor series (Taylor1, TaylorN, nested): Newton on the whole series, started from
# the implied volatility of the constant terms (see blimpv_series_newton)
function blimpv_impl(::Type{<:TaylorType}, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    σ0 = blimpv(constant_value(S0), constant_value(K), constant_value(T), constant_value(price_d), FlagIsCall, xtol, n_iter_max)
    σ = lift_to_series(lift_to_series(lift_to_series(lift_to_series(σ0, S0), K), T), price_d)
    return blimpv_series_newton(σ, S0, K, T, price_d, FlagIsCall, series_order(σ))
end

end
