function blprice_and_vega(S0, K, x, sqrtT, σ, FlagIsCall)
    #I avoid the checks for the inputs since we have already checked them apart of volatility.
    #The volatility is positive by construction.
    d1 = sqrtT * (x / σ + σ / 2)
    d2 = d1 - σ * sqrtT
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
    Price = iscall * (S0 * normcdf(iscall * d1) - K * normcdf(iscall * d2))
    ν = S0 * normpdf(d1) * sqrtT
    return Price, ν
end

function iter_blimpv(S0, K, x, sqrtT, price, FlagIsCall, σ, eps_adj)
    cur_price, cur_vega = blprice_and_vega(S0, K, x, sqrtT, σ, FlagIsCall)
    σ_new = max(σ + (price - cur_price) / cur_vega, eps_adj)
    return ifelse(isnan(σ_new), eps_adj, σ_new)
end

function fixed_point_blimpv(S0, K, T, price, FlagIsCall, xtol, ytol)
    num, den = ifelse(FlagIsCall, (S0, K), (K, S0))
    res = (num - price) / den
    sqrtT = sqrt(T)
    x = log(S0 / K) / T
    σ_cur = sqrt(abs(log(res)))
    eps_type = typeof(x + price)
    eps_adj = eps(eps_type)
    max_iter = 80
    for _ = 1:max_iter
        σ_new = iter_blimpv(S0, K, x, sqrtT, price, FlagIsCall, σ_cur, eps_adj)
        diff = abs(σ_new - σ_cur)
        if diff < xtol
            return σ_new
        end
        σ_cur = σ_new
    end
    @warn "max number of iterations reached, a NaN result will be returned."
    return eps_type(NaN)
end

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

function blimpv_impl(::AbstractFloat, S0, K, T, price_d, FlagIsCall, xtol, ytol)
    ChainRulesCore.ignore_derivatives() do
        FinancialToolbox.blimpv_check(S0, K, T)
        if xtol <= 0.0
            throw(DomainError(xtol, "x tollerance cannot be negative"))
        end
        if ytol <= 0.0
            throw(DomainError(ytol, "y tollerance cannot be negative"))
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
    return fixed_point_blimpv(S0, K, T, price_d, FlagIsCall, xtol, ytol)
end

function blimpv(S0::num1, K::num2, T::num4, Price::num5, FlagIsCall::Bool = true, xtol::Real = 1e-14, ytol::Real = 1e-15) where {num1, num2, num4, num5}
    zero_typed = ChainRulesCore.@ignore_derivatives(zero(promote_type(num1, num2, num4, num5)))
    σ = blimpv_impl(zero_typed, S0, K, T, Price, FlagIsCall, xtol, ytol)
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
function blsimpv(S0, K, r, T, Price, d = 0, FlagIsCall::Bool = true, xtol::Real = 1e-14, ytol::Real = 1e-15)
    cv = exp(r * T)
    cv2 = exp(-d * T)
    adj_S0 = S0 * cv * cv2
    adj_price = Price * cv
    σ = blimpv(adj_S0, K, T, adj_price, FlagIsCall, xtol, ytol)
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
function blkimpv(F0, K, r, T, Price, FlagIsCall::Bool = true, xtol::Real = 1e-14, ytol::Real = 1e-15)
    adj_price = Price * exp(r * T)
    σ = blimpv(F0, K, T, adj_price, FlagIsCall, xtol, ytol)
    return σ
end

import ChainRulesCore: rrule, frule, NoTangent, @thunk, rrule_via_ad

function rrule(config::RuleConfig{>:HasReverseMode}, ::typeof(blimpv), S0, K, T, price_d, FlagIsCall, xtol, ytol)
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, ytol)
    function update_pullback(slice)
        _, pullback_blprice = ChainRulesCore.rrule_via_ad(config, blprice_impl, S0, K, T, σ, FlagIsCall)
        _, der_S0, der_K, der_T, der_σ = pullback_blprice(slice)
        slice_mod = -inv(der_σ)
        return NoTangent(), slice_mod * der_S0, slice_mod * der_K, slice_mod * der_T, -slice_mod, NoTangent(), NoTangent(), NoTangent()
    end
    return σ, update_pullback
end

# function frule(config::RuleConfig{>:HasForwardsMode}, (Δf, dS, dK, dT, dprice, _, _, _), ::typeof(blimpv), S0, K, T, price_d, FlagIsCall::Bool, xtol::AbstractFloat, ytol::AbstractFloat)
#     σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, ytol)
#     vega = blvega_impl(S0, K, T, σ)
#     _, der_fwd = ChainRulesCore.frule_via_ad(config, (Δf, dS, dK, dT, dprice), blprice_impl, S0, K, T, σ, FlagIsCall)
#     return σ, -der_fwd / vega
# end