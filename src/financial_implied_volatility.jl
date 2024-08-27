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
function blsimpv(S0, K, r, T, Price, d = 0, FlagIsCall::Bool = true, xtol::Real = 100 * eps(Float64), n_iter_max::Integer = 4)
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

import ChainRulesCore: rrule, frule, NoTangent, @thunk, rrule_via_ad, frule_via_ad

function blprice_diff_impl(S0, K, T, σ, price_d, FlagIsCall)
    return price_d - blprice_impl(S0, K, T, σ, FlagIsCall)
end

function rrule(config::RuleConfig{>:HasReverseMode}, ::typeof(blimpv), S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    function update_pullback(slice)
        _, pullback_blprice = ChainRulesCore.rrule_via_ad(config, blprice_impl, S0, K, T, σ, FlagIsCall)
        _, der_S0, der_K, der_T, der_σ, _ = pullback_blprice(slice)
        slice_mod = -inv(der_σ)
        return NoTangent(), slice_mod * der_S0, slice_mod * der_K, slice_mod * der_T, -slice_mod, NoTangent(), NoTangent(), NoTangent()
    end
    return σ, update_pullback
end


function frule(config::RuleConfig{>:HasForwardsMode}, (_, dS, dK, dT, dprice, _, _, _), ::typeof(blimpv), S0, K, T, price_d, FlagIsCall::Bool, xtol, n_iter_max::Integer)
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    vega = blvega_impl(S0, K, T, σ)
    _, der_fwd = ChainRulesCore.frule_via_ad(config, (NoTangent(), dS, dK, dT, NoTangent(), dprice, NoTangent()), blprice_diff_impl, S0, K, T, σ, price_d, FlagIsCall)
    return σ, der_fwd / vega
end