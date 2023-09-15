#Brent Method: Scalar Equation Solver
function brentMethod(f::Function, x0::Number, x1::Number, xtol::AbstractFloat = 1e-14, ytol::AbstractFloat = 1e-15)
    if xtol < 0.0
        throw(ErrorException("x tollerance cannot be negative"))
    end
    if ytol < 0.0
        throw(ErrorException("y tollerance cannot be negative"))
    end
    EPS = eps(x0)
    maxiter = 80
    y0 = f(x0)
    y1 = f(x1)
    if (y0 * y1 > 0)
        throw(DomainError("There is no such volatility"))
    end
    if abs(y0) < abs(y1)
        # Swap lower and upper bounds.
        x0, x1 = x1, x0
        y0, y1 = y1, y0
    end
    x2 = x0
    y2 = y0
    x3 = x2
    bisection = true
    for _ = 1:maxiter
        # x-tolerance.
        if abs(x1 - x0) < xtol
            return x1
        end

        # Use inverse quadratic interpolation if f(x0)!=f(x1)!=f(x2)
        # and linear interpolation (secant method) otherwise.
        if abs(y0 - y2) > ytol && abs(y1 - y2) > ytol
            x = x0 * y1 * y2 / ((y0 - y1) * (y0 - y2)) + x1 * y0 * y2 / ((y1 - y0) * (y1 - y2)) + x2 * y0 * y1 / ((y2 - y0) * (y2 - y1))
        else
            x = x1 - y1 * (x1 - x0) / (y1 - y0)
        end

        # Use bisection method if satisfies the conditions.
        delta = abs(2EPS * abs(x1))
        min1 = abs(x - x1)
        min2 = abs(x1 - x2)
        min3 = abs(x2 - x3)
        if (x < (3x0 + x1) / 4 && x > x1) || (bisection && min1 >= min2 / 2) || (!bisection && min1 >= min3 / 2) || (bisection && min2 < delta) || (!bisection && min3 < delta)
            x = (x0 + x1) / 2
            bisection = true
        else
            bisection = false
        end
        y = f(x)
        if abs(x - x0) < xtol
            return x
        end
        x3 = x2
        x2 = x1
        if sign(y0) != sign(y)
            x1 = x
            y1 = y
        else
            x0 = x
            y0 = y
        end
        if abs(y0) < abs(y1)
            # Swap lower and upper bounds.
            x0, x1 = x1, x0
            y0, y1 = y1, y0
        end
    end
    throw(ErrorException("Max iteration exceeded, possible wrong result"))
end

function blprice_and_vega(S0, K, x, sqrtT, σ, FlagIsCall)
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, sqrtT, σ))
    d1 = sqrtT * (x / σ + σ / 2)
    d2 = d1 - σ * sqrtT
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
    Price = iscall * (S0 * normcdf(iscall * d1) - K * normcdf(iscall * d2))
    ν = S0 * normpdf(d1) * sqrtT
    return Price, ν
end

function iter_blimpv(S0, K, x, sqrtT, price, FlagIsCall, cur_sigma)
    cur_price, cur_vega = blprice_and_vega(S0, K, x, sqrtT, cur_sigma, FlagIsCall)
    new_sigma = cur_sigma + (price - cur_price) / cur_vega
    eps_adj = eps(typeof(new_sigma))
    new_sigma = max(new_sigma, eps_adj)
    return ifelse(isnan(new_sigma), eps_adj, new_sigma)
end

function fixed_point_blimpv(S0, K, T, price, FlagIsCall, xtol, ytol)
    if xtol <= 0.0
        throw(ErrorException("x tollerance cannot be negative"))
    end
    num, den = ifelse(FlagIsCall, (S0, K), (K, S0))
    res = (num - price) / den
    sqrtT = sqrt(T)
    x = log(S0 / K) / T
    cur_sigma = sqrt(abs(log(res)))
    max_iter = 80
    for _ = 1:max_iter
        new_sigma = iter_blimpv(S0, K, x, sqrtT, price, FlagIsCall, cur_sigma)
        diff = abs(new_sigma - cur_sigma)
        if diff < xtol
            return new_sigma
        end
        cur_sigma = new_sigma
    end
    @warn "max number of iterations reached, switching to bracketing method."
    # f(σ)=ifelse(σ>=0.0,price_t-blsprice2(S0, K, r, T, σ, d),price_t-blsprice2(S0, K, r, T, σ, d)-S0*exp(-r*T)+K*exp(-d*T))
    # TODO: extend the folliwing to support negative sigmas.
    f(x) = blprice(S0, K, T, x, FlagIsCall) - price
    zero_typed = 0 * +(S0, K, T, price)
    σ_min = zero_typed + 1 // 100000
    σ_max = zero_typed + 102 // 10
    σ = brentMethod(f, σ_min, σ_max, xtol, ytol)
    return σ
end

function blimpv_impl(::AbstractFloat, S0, K, T, price_d, FlagIsCall, xtol, ytol)
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T))
    if ytol <= 0.0
        throw(ErrorException("y tollerance cannot be negative"))
    end
    max_price = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, S0, K))
    if max_price <= price_d
        throw(ErrorException("Price is reaching maximum value"))
    end
    min_price = ChainRulesCore.@ignore_derivatives(eps(zero(price_d)))
    if min_price >= price_d
        throw(ErrorException("Price is reaching minimum value"))
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
        dy = @thunk(pullback_blprice(slice))
        @views der_S0 = dy[2]
        @views der_K = dy[3]
        @views der_T = dy[4]
        @views slice_mod = @thunk(-inv(dy[5]))
        return NoTangent(), @thunk(slice_mod * der_S0), @thunk(slice_mod * der_K), @thunk(slice_mod * der_T), @thunk(-slice_mod), NoTangent(), NoTangent(), NoTangent()
    end
    return σ, update_pullback
end