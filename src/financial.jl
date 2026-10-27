using IrrationalConstants
const one_internal = Int8(1)
const minus_one_internal = Int8(-1)
const two_internal = Int8(2)
# ±1 for calls and puts. Declared non differentiable rather than wrapped in @ignore_derivatives at the call site,
# which costs Zygote tens of microseconds per call.
call_put_sign(FlagIsCall::Bool) = ifelse(FlagIsCall, one_internal, minus_one_internal)
ChainRulesCore.@non_differentiable call_put_sign(::Bool)
"""
Cumulative Distribution Function of a Standard Gaussian Random Variable

		y=normcdf(x)

Where:\n
		x         = point of evaluation.

		y      = probability that a standard gaussian random variable is below x.

# Example
```julia-repl
julia> normcdf(0.0)
0.5
```
"""
function normcdf(x)
    return erfc(-x * invsqrt2) / two_internal
end

"""
Probability Distribution Function of a Standard Gaussian Random Variable

		y=normpdf(x)

Where:\n
		x         = point of evaluation.

		y      = value.

# Example
```julia-repl
julia> normpdf(0.0)
0.3989422804014327
```
"""
function normpdf(x)
    return exp(x^2 / (-two_internal)) * invsqrt2π
end

"""
Black Price for Binary European Options

		Price=blsbin(S0,K,r,T,σ,FlagIsCall=true)

Where:\n
		F0         = Value of the Forward.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility.
		FlagIsCall = true for Call Options, false for Put Options.

		Price      = price of the Binary European Option.

# Example
```julia-repl
julia> blsbin(10.0,10.0,0.01,2.0,0.2)
0.4624714677292208
```
"""
function blsbin(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d2 = (log(S0 / K) + rt + dt) / sigma_sqrtT - sigma_sqrtT / two_internal
    iscall = call_put_sign(FlagIsCall)
    Price = exp(-rt) * normcdf(iscall * d2)
    return Price
end

"""
Black & Scholes Delta for European Options

		Δ=blsdelta(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		Δ          = delta of the European Option.

# Example
```julia-repl
julia> blsdelta(10.0,10.0,0.01,2.0,0.2,0.01)
0.5452173371920436
```
"""
function blsdelta(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    iscall = call_put_sign(FlagIsCall)
    Δ = exp(dt) * normcdf(iscall * d1) * iscall
    return Δ
end

function blprice_impl(S0, K, T, σ, FlagIsCall::Bool = true)
    iscall = call_put_sign(FlagIsCall)
    sigma_sqrtT = σ * sqrt(T)
    d1 = log(S0 / K) / sigma_sqrtT + sigma_sqrtT / two_internal
    Price = iscall * (S0 * normcdf(iscall * d1) - K * normcdf(iscall * (d1 - sigma_sqrtT)))
    return Price
end

# Price of blprice_impl and its closed form partial derivatives with respect to S0, K, T and σ:
# ∂S0 = ±N(±d1), ∂K = ∓N(±d2), ∂σ = S0 φ(d1) √T (vega) and ∂T = vega σ / (2T)
function blprice_and_sensitivities(S0, K, T, σ, FlagIsCall::Bool)
    iscall = call_put_sign(FlagIsCall)
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d1 = log(S0 / K) / sigma_sqrtT + sigma_sqrtT / two_internal
    der_S0 = iscall * normcdf(iscall * d1)
    der_K = -iscall * normcdf(iscall * (d1 - sigma_sqrtT))
    Price = S0 * der_S0 + K * der_K
    vega = S0 * normpdf(d1) * sqrtT
    return Price, der_S0, der_K, vega * σ / (two_internal * T), vega
end

# The derivatives of the Black formula are known in closed form: AD engines using ChainRulesCore rules don't
# need to differentiate through it
function ChainRulesCore.rrule(::typeof(blprice_impl), S0, K, T, σ, FlagIsCall::Bool)
    Price, der_S0, der_K, der_T, der_σ = blprice_and_sensitivities(S0, K, T, σ, FlagIsCall)
    function blprice_impl_pullback(slice)
        return ChainRulesCore.NoTangent(), slice * der_S0, slice * der_K, slice * der_T, slice * der_σ, ChainRulesCore.NoTangent()
    end
    return Price, blprice_impl_pullback
end

function ChainRulesCore.frule((_, dS0, dK, dT, dσ, _), ::typeof(blprice_impl), S0, K, T, σ, FlagIsCall::Bool)
    Price, der_S0, der_K, der_T, der_σ = blprice_and_sensitivities(S0, K, T, σ, FlagIsCall)
    return Price, dS0 * der_S0 + dK * der_K + dT * der_T + dσ * der_σ
end

function blprice(S0, K, T, σ, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    return blprice_impl(S0, K, T, σ, FlagIsCall)
end
"""
Black & Scholes Price for European Options

		Price=blsprice(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		Price      = price of the European Option.

# Example
```julia-repl
julia> blsprice(10.0,10.0,0.01,2.0,0.2,0.01)
1.1023600107733191
```
"""
function blsprice(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    cv = exp(r * T)
    cv2 = exp((r - d) * T)
    F = S0 * cv2
    return blprice(F, K, T, σ, FlagIsCall) / cv
end
"""
Black Price for European Options

		Price=blkprice(F0,K,r,T,σ,FlagIsCall=true)

Where:\n
		F0         = Value of the Forward.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility.
		FlagIsCall = true for Call Options, false for Put Options.

		Price      = price of the European Option.

# Example
```julia-repl
julia> blkprice(10.0,10.0,0.01,2.0,0.2)
1.1023600107733191
```
"""
function blkprice(F0, K, r, T, σ, FlagIsCall::Bool = true)
    cv = exp(r * T)
    return blprice(F0, K, T, σ, FlagIsCall) / cv
end
"""
Black & Scholes Gamma for European Options

		Γ=blsgamma(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		Γ          = gamma of the European Option.

# Example
```julia-repl
julia> blsgamma(10.0,10.0,0.01,2.0,0.2,0.01)
0.13687881535712826
```
"""
function blsgamma(S0, K, r, T, σ, d, ::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    Γ = exp(dt) * normpdf(d1) / (S0 * sigma_sqrtT)
    return Γ
end
function blvega_impl(S0, K, T, σ)
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d1 = log(S0 / K) / sigma_sqrtT + sigma_sqrtT / two_internal
    ν = S0 * normpdf(d1) * sqrtT
    return ν
end
function blvega(S0, K, T, σ)
    blcheck(S0, K, T, σ)
    return blvega_impl(S0, K, T, σ)
end
"""
Black & Scholes Vega for European Options

		ν=blsvega(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		ν          = vega of the European Option.

# Example
```julia-repl
julia> blsvega(10.0,10.0,0.01,2.0,0.2,0.01)
5.475152614285131
```
"""
function blsvega(S0, K, r, T, σ, d, ::Bool = true)
    cv = exp(r * T)
    cv2 = exp(-d * T)
    F = S0 * cv * cv2
    return blvega(F, K, T, σ) / cv
end

"""
Black & Scholes Rho for European Options

		ρ=blsrho(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		ρ          = rho of the European Option.

# Example
```julia-repl
julia> blsrho(10.0,10.0,0.01,2.0,0.2,0.01)
8.699626722294234
```
"""
function blsrho(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    iscall = call_put_sign(FlagIsCall)
    rt = r * T
    dt = -d * T
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d2 = (log(S0 / K) + rt + dt) / sigma_sqrtT - sigma_sqrtT / two_internal
    ρ = iscall * K * exp(-rt) * normcdf(iscall * d2) * T
    return ρ
end

"""
Black & Scholes Theta for European Options

		Θ=blstheta(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		Θ          = theta of the European Option.

# Example
```julia-repl
julia> blstheta(10.0,10.0,0.01,2.0,0.2,0.01)
-0.26273403060652334
```
"""
function blstheta(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d1 = (log(S0 / K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    d2 = d1 - sigma_sqrtT
    S0_adj = S0 * exp(dt)
    shift = -S0_adj * normpdf(d1) * σ / (sqrtT * two_internal)
    t1 = r * K * exp(-rt)
    t2 = d * S0_adj
    iscall = call_put_sign(FlagIsCall)
    Θ = shift - iscall * (t1 * normcdf(iscall * d2) - t2 * normcdf(iscall * d1))
    return Θ
end

"""
Black & Scholes Lambda for European Options

		Λ=blslambda(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		Λ          = lambda of the European Option.

# Example
```julia-repl
julia> blslambda(10.0,10.0,0.01,2.0,0.2,0.01)
4.945909973725978
```
"""
function blslambda(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    d2 = d1 - sigma_sqrtT
    iscall = call_put_sign(FlagIsCall)
    Δ = exp(dt) * normcdf(iscall * d1) * iscall
    Δ_adj = S0 * Δ
    Price = Δ_adj - iscall * K * exp(-rt) * normcdf(iscall * d2)
    Λ = Δ_adj / Price
    return Λ
end

#Check input for Black Scholes Formula
function blcheck_impl(::num0, S0::num1, K::num2, T::num4, σ::num5) where {num0, num1, num2, num4, num5}
    lesseq(x, y) = x <= y
    if (lesseq(S0, zero(num1)))
        throw(DomainError(S0, "Spot Price Cannot Be Negative"))
    elseif (lesseq(K, zero(num2)))
        throw(DomainError(K, "Strike Price Cannot Be Negative"))
    elseif (lesseq(T, zero(num4)))
        throw(DomainError(T, "Time to Maturity Cannot Be Negative"))
    elseif (lesseq(σ, zero(num5)))
        throw(DomainError(σ, "Volatility Cannot Be Negative"))
    end
    return
end
function blcheck_impl(::num0, S0::num1, K::num2, T::num4, σ::num5) where {num0 <: Complex, num1, num2, num4, num5}
    lesseq(x::Complex, y::Complex) = real(x) <= real(y)
    lesseq(x, y) = x <= y
    if (lesseq(S0, zero(num1)))
        throw(DomainError(S0, "Spot Price Cannot Be Negative"))
    elseif (lesseq(K, zero(num2)))
        throw(DomainError(K, "Strike Price Cannot Be Negative"))
    elseif (lesseq(T, zero(num4)))
        throw(DomainError(T, "Time to Maturity Cannot Be Negative"))
    elseif (lesseq(σ, zero(num5)))
        throw(DomainError(σ, "Volatility Cannot Be Negative"))
    end
    return
end

function blcheck(S0::num1, K::num2, T::num4, σ::num5) where {num1, num2, num4, num5}
    zero_typed = S0 * K * T * σ
    blcheck_impl(zero_typed, S0, K, T, σ)
    return
end
# Domain checks only (see call_put_sign)
ChainRulesCore.@non_differentiable blcheck(::Any, ::Any, ::Any, ::Any)
##	ADDITIONAL Functions

"""
Black & Scholes Psi for European Options

		Ψ=blspsi(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		Ψ          = psi of the European Option.

# Example
```julia-repl
julia> blspsi(10.0,10.0,0.01,2.0,0.2,0.01)
-10.904346743840872
```
"""
function blspsi(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    iscall = call_put_sign(FlagIsCall)
    Ψ = -iscall * S0 * exp(dt) * normcdf(iscall * d1) * T
    return Ψ
end

"""
Black & Scholes Vanna for European Options

		Vanna=blsvanna(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
		S0         = Value of the Underlying.
		K          = Strike Price of the Option.
		r          = Zero Rate.
		T          = Time to Maturity of the Option.
		σ          = Implied Volatility
		d          = Implied Dividend of the Underlying.
		FlagIsCall = true for Call Options, false for Put Options.

		Vanna        = vanna of the European Option.

# Example
```julia-repl
julia> blsvanna(10.0,10.0,0.01,2.0,0.2,0.01)
0.2737576307142566
```
"""
function blsvanna(S0, K, r, T, σ, d, ::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    d2 = d1 - sigma_sqrtT
    Vanna = -exp(dt) * normpdf(d1) * d2 / σ
    return Vanna
end
