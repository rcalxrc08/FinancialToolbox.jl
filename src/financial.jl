using IrrationalConstants
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
    return erfc(-x / sqrt2) / 2
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
    return exp(-x^2 / 2) / sqrt2π
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
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
    rt = r * T
    dt = -d * T
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d2 = (log(S0 / K) + rt + dt) / sigma_sqrtT - sigma_sqrtT / 2
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
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
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
    Δ = exp(dt) * normcdf(iscall * d1) * iscall
    return Δ
end

function blprice_impl(S0, K, T, σ, FlagIsCall::Bool = true)
    iscall = ifelse(ChainRulesCore.@ignore_derivatives(FlagIsCall), 1, -1)
    sigma_sqrtT = σ * sqrt(T)
    d1 = log(S0 / K) / sigma_sqrtT + sigma_sqrtT / 2
    Price = iscall * (S0 * normcdf(iscall * d1) - K * normcdf(iscall * (d1 - sigma_sqrtT)))
    return Price
end
function blprice(S0, K, T, σ, FlagIsCall::Bool = true)
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
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
    cv2 = exp(-d * T)
    F = S0 * cv * cv2
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
    cv = exp(-r * T)
    return blprice(F0, K, T, σ, FlagIsCall) * cv
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
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    Γ = exp(dt) * normpdf(d1) / (S0 * sigma_sqrtT)
    return Γ
end
function blvega_impl(S0, K, T, σ)
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d1 = log(S0 / K) / sigma_sqrtT + sigma_sqrtT / 2
    ν = S0 * normpdf(d1) * sqrtT
    return ν
end
function blvega(S0, K, T, σ)
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
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
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
    rt = r * T
    dt = -d * T
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d2 = (log(S0 / K) + rt + dt) / sigma_sqrtT - sigma_sqrtT / 2
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
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
    rt = r * T
    dt = -d * T
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d1 = (log(S0 / K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    d2 = d1 - sigma_sqrtT
    shift = -exp(dt) * S0 * normpdf(d1) * σ / 2 / sqrtT
    t1 = r * K * exp(-rt)
    t2 = d * S0 * exp(dt)
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
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
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    d2 = d1 - sigma_sqrtT
    iscall = ifelse(ChainRulesCore.@ignore_derivatives(FlagIsCall), 1, -1)
    Δ = exp(dt) * normcdf(iscall * d1) * iscall
    Δ_adj = S0 * Δ
    Price = Δ_adj - iscall * K * exp(-rt) * normcdf(iscall * d2)
    Λ = Δ_adj / Price
    return Λ
end

"""Check input for Black Scholes Formula"""
function blcheck(S0::num1, K::num2, T::num4, σ::num5 = 1) where {num1, num2, num4, num5}
    lesseq(x::Complex, y::Complex) = real(x) <= real(y)
    lesseq(x, y) = x <= y
    if (lesseq(S0, zero(num1)))
        error("Spot Price Cannot Be Negative")
    elseif (lesseq(K, zero(num2)))
        error("Strike Price Cannot Be Negative")
    elseif (lesseq(T, zero(num4)))
        error("Time to Maturity Cannot Be Negative")
    elseif (lesseq(σ, zero(num5)))
        error("Volatility Cannot Be Negative")
    end
    return
end
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
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
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
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blcheck(S0, K, T, σ))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    d2 = d1 - sigma_sqrtT
    Vanna = -exp(dt) * normpdf(d1) * d2 / σ
    return Vanna
end
