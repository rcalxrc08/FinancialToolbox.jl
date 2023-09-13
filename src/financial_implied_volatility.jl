using IrrationalConstants

"Brent Method: Scalar Equation Solver"
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

function price_and_vega(S0, K, r, T, σ, d, FlagIsCall)
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
    rt = r * T
    dt = -d * T
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d1 = (log(S0 / K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    d2 = d1 - sigma_sqrtT
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
    common_term = S0 * exp(dt)
    Price = iscall * (common_term * normcdf(iscall * d1) - K * exp(-rt) * normcdf(iscall * d2))
    ν = common_term * normpdf(d1) * sqrtT
    return Price, ν
end

function iter_blsimpv(S0, K, r, T, price, d, FlagIsCall, cur_sigma)
    cur_price, cur_vega = price_and_vega(S0, K, r, T, cur_sigma, d, FlagIsCall)
    new_sigma = cur_sigma + (price - cur_price) / cur_vega
    eps_adj = eps(typeof(new_sigma))
    new_sigma = max(new_sigma, eps_adj)
    return ifelse(isnan(new_sigma), eps_adj, new_sigma)
end
function fixed_point_blsimpv(S0, K, r, T, price, d, FlagIsCall, xtol, ytol)
    if xtol <= 0.0
        throw(ErrorException("x tollerance cannot be negative"))
    end
    adj_S0 = S0 * exp(-d * T)
    disc_K = K * exp(r * T)
    num, den = ifelse(FlagIsCall, (adj_S0, disc_K), (disc_K, adj_S0))
    res = (num - price) / den
    cur_sigma = sqrt(abs(log(res)))
    max_iter = 80
    for _ = 1:max_iter
        new_sigma = iter_blsimpv(S0, K, r, T, price, d, FlagIsCall, cur_sigma)
        diff = abs(new_sigma - cur_sigma)
        if diff < xtol
            return new_sigma
        end
        cur_sigma = new_sigma
    end
    @warn "max number of iterations reached, switching to bracketing method."
    # f(sigma)=ifelse(sigma>=0.0,price_t-blsprice2(S0, K, r, T, sigma, d),price_t-blsprice2(S0, K, r, T, sigma, d)-S0*exp(-r*T)+K*exp(-d*T))
    # TODO: extend the folliwing to support negative sigmas.
    f(x) = blsprice(S0, K, r, T, x, d, FlagIsCall) - price
    zero_typed = 0 * +(S0, K, r, T, price, d)
    σ = brentMethod(f, typeof(zero_typed)(0.00001), typeof(zero_typed)(10.2), xtol, ytol)
    return σ
end

function blsimpv_impl(::AbstractFloat, S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
    if ytol <= 0.0
        throw(ErrorException("y tollerance cannot be negative"))
    end
    if S0 * exp(-d * T) <= price_d
        throw(ErrorException("y tollerance cannot be negative"))
    end
    return fixed_point_blsimpv(S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
end

function check_positive_price(price::num) where {num <: Number}
    lesseq(x::Complex, y::Complex) = real(x) <= real(y)
    lesseq(x, y) = x <= y
    if (lesseq(price, zero(num)))
        throw(ErrorException("Option Price Cannot Be Negative"))
    end
end
export blsimpv
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
function blsimpv(S0::num1, K::num2, r::num3, T::num4, Price::num5, d::num6 = 0, FlagIsCall::Bool = true, xtol::Real = 1e-14, ytol::Real = 1e-15) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.check_positive_price(Price))
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, 0.1, d))
    zero_typed = ChainRulesCore.@ignore_derivatives(zero(promote_type(num1, num2, num3, num4, num5, num6)))
    σ = blsimpv_impl(zero_typed, S0, K, r, T, Price, d, FlagIsCall, xtol, ytol)
    return σ
end

export blkimpv
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
function blkimpv(F0::num1, K::num2, r::num3, T::num4, Price::num5, FlagIsCall::Bool = true, xtol::Real = 1e-14, ytol::Real = 1e-15) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(F0, K, r, T, 0.1))
    σ = blsimpv(F0, K, r, T, Price, r, FlagIsCall, xtol, ytol)
    return σ
end

import ChainRulesCore: rrule, frule, NoTangent, @thunk, rrule_via_ad
function rrule(config::RuleConfig{>:HasReverseMode}, ::typeof(blsimpv), S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
    sigma = blsimpv(S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
    function update_pullback(slice)
        _, pullback_blsprice = ChainRulesCore.rrule_via_ad(config, blsprice, S0, K, r, T, sigma, d, FlagIsCall)
        dy = @thunk(pullback_blsprice(slice))
        @views der_S0 = dy[2]
        @views der_K = dy[3]
        @views der_r = dy[4]
        @views der_T = dy[5]
        @views der_d = dy[7]
        @views slice_mod = @thunk(-inv(dy[6]))
        return NoTangent(), @thunk(slice_mod * der_S0), @thunk(slice_mod * der_K), @thunk(slice_mod * der_r), @thunk(slice_mod * der_T), @thunk(-slice_mod), @thunk(slice_mod * der_d), NoTangent(), NoTangent(), NoTangent()
    end
    return sigma, update_pullback
end
