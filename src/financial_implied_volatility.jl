function blimpv_check(S0::num1, K::num2, T::num4) where {num1, num2, num4}
    lesseq(x::Complex, y::Complex) = real(x) <= real(y)
    lesseq(x, y) = x <= y
    if (lesseq(S0, zero(num1)))
        throw(DomainError(S0, "Spot Price Cannot Be Negative"))
    elseif (lesseq(K, zero(num2)))
        throw(DomainError(K, "Strike Price Cannot Be Negative"))
    elseif (lesseq(T, zero(num4)))
        throw(DomainError(T, "Time to Maturity Cannot Be Negative"))
    end
    return
end

function blimpv_impl(::AbstractFloat, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    ChainRulesCore.ignore_derivatives() do
        FinancialToolbox.blimpv_check(S0, K, T)
        if xtol <= 0.0
            throw(DomainError(xtol, "x tollerance cannot be negative"))
        end
        if n_iter_max <= 0
            throw(DomainError(n_iter_max, "maximum number of iterations must be positive"))
        end
        max_price = ifelse(FlagIsCall, S0, K)
        if max_price <= price_d
            throw(DomainError(price_d, "Price is reaching maximum value"))
        end
        min_price = eps(zero(price_d))
        if min_price >= price_d
            throw(DomainError(price_d, "Price is reaching minimum value"))
        end
    end
    return blimpv_lets_be_rational(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
end

# Complex inputs: blprice(σ) = price has many complex roots σ. This returns the analytic continuation of the
# real implied volatility (the root used by the complex step approximation): Newton in the complex plane,
# σ ← σ + (price - blprice(σ)) / vega(σ), started from the implied volatility of the real parts.
# Newton converges quadratically, in one or two steps for complex step perturbations.
function blimpv_impl(::Complex, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    σ = complex(blimpv(real(S0), real(K), real(T), real(price_d), FlagIsCall, xtol, n_iter_max))
    max_iter = 100
    for _ = 1:max_iter
        Δ = (price_d - blprice_impl(S0, K, T, σ, FlagIsCall)) / blvega_impl(S0, K, T, σ)
        σ += Δ
        if abs(Δ) <= xtol * abs(σ)
            return σ
        end
    end
    throw(DomainError(price_d, "Newton for the complex implied volatility did not converge in $max_iter iterations, the imaginary parts may be too large"))
end

function blimpv(S0::num1, K::num2, T::num4, Price::num5, FlagIsCall::Bool, xtol::Real, n_iter_max::Integer) where {num1, num2, num4, num5}
    zero_typed = ChainRulesCore.@ignore_derivatives(zero(promote_type(num1, num2, num4, num5)))
    σ = blimpv_impl(zero_typed, S0, K, T, Price, FlagIsCall, xtol, n_iter_max)
    return σ
end

"""
Black & Scholes Implied Volatility for European Options

		σ=blsimpv(S0,K,r,T,Price,d=0.0,FlagIsCall=true,xtol=1e-14,ytol=1e-15)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		Price      = Price of the Option.
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		σ          = implied volatility of the European Option.

# Example
```julia-repl
julia> blsimpv(10.0,10.0,0.01,2.0,2.0)
0.3433730534290586
```
"""
function blsimpv(S0, K, r, T, Price, d, FlagIsCall::Bool=true, xtol::Real=100 * eps(Float64), n_iter_max::Integer=4)
    cv = exp(r * T)
    cv2 = exp(-d * T)
    adj_S0 = S0 * cv * cv2
    adj_price = Price * cv
    σ = blimpv(adj_S0, K, T, adj_price, FlagIsCall, xtol, n_iter_max)
    return σ
end

"""
Black Implied Volatility for European Options

		σ=blkimpv(F0,K,r,T,Price,FlagIsCall=true,xtol=1e-14,ytol=1e-15)

Where:\n
		F0         = Value of the Forward.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		Price      = Price of the Option.
		FlagIsCall = true for Call Options, false for Put Options.

		σ          = implied volatility of the European Option.

# Example
```julia-repl
julia> blkimpv(10.0,10.0,0.01,2.0,2.0)
0.36568658096623635
```
"""
function blkimpv(F0, K, r, T, Price, FlagIsCall::Bool = true, xtol::Real = 1e-14, n_iter_max::Integer = 4)
    adj_price = Price * exp(r * T)
    σ = blimpv(F0, K, T, adj_price, FlagIsCall, xtol, n_iter_max)
    return σ
end

import ChainRulesCore: rrule, frule, NoTangent

function blprice_diff_impl(S0, K, T, σ, price_d, FlagIsCall)
    return price_d - blprice_impl(S0, K, T, σ, FlagIsCall)
end

# Sensitivities of σ = blimpv(S0, K, T, price_d) via the implicit function theorem:
# dσ/dθ = -(∂P/∂θ) / vega, with closed-form partials of blprice_impl.
function blimpv_sensitivities(S0, K, T, σ, FlagIsCall::Bool)
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d1 = log(S0 / K) / sigma_sqrtT + sigma_sqrtT / two_internal
    inv_vega = inv(S0 * normpdf(d1) * sqrtT)
    nd1 = normcdf(d1)
    nd2 = normcdf(d1 - sigma_sqrtT)
    der_S0 = ifelse(FlagIsCall, nd1, nd1 - one_internal)
    der_K = ifelse(FlagIsCall, -nd2, one_internal - nd2)
    return -der_S0 * inv_vega, -der_K * inv_vega, -σ / (two_internal * T), inv_vega
end

# Implied volatility of truncated Taylor polynomials (TaylorSeries and TaylorDiff extensions). σ(t) is only
# defined implicitly by blprice(σ(t)) = price(t), so its coefficients come from Newton on the whole series,
# σ ← σ + (price - blprice(σ)) / vega(σ), started from σ, the implied volatility of the constant terms.
# This is exact, not an approximation: the error of the start is O(t) and each step squares it, so after
# m steps it is O(t^(2^m)), beyond the truncation order once 2^m > order. Hence the fixed number of steps
# and no convergence check; only rounding and the accuracy of the constant term (xtol) remain.
# Solving one coefficient at a time with the constant vega is equivalent but needs `order` steps.
function blimpv_series_newton(σ, S0, K, T, price_d, FlagIsCall::Bool, order::Integer)
    for _ = 1:ceil(Int, log2(order + 1))
        σ += (price_d - blprice_impl(S0, K, T, σ, FlagIsCall)) / blvega_impl(S0, K, T, σ)
    end
    return σ
end

function rrule(::typeof(blimpv), S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    function update_pullback(slice)
        der_S0, der_K, der_T, der_price = blimpv_sensitivities(S0, K, T, σ, FlagIsCall)
        return NoTangent(), slice * der_S0, slice * der_K, slice * der_T, slice * der_price, NoTangent(), NoTangent(), NoTangent()
    end
    return σ, update_pullback
end

function frule((_, dS, dK, dT, dprice, _, _, _), ::typeof(blimpv), S0, K, T, price_d, FlagIsCall::Bool, xtol, n_iter_max::Integer)
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    der_S0, der_K, der_T, der_price = blimpv_sensitivities(S0, K, T, σ, FlagIsCall)
    return σ, dS * der_S0 + dK * der_K + dT * der_T + dprice * der_price
end