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
function normcdf(x::number) where {number}
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
function normpdf(x::number) where {number <: Number}
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
function blsbin(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, FlagIsCall::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
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
function blsdelta(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, FlagIsCall::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    iscall = ChainRulesCore.@ignore_derivatives(ifelse(FlagIsCall, 1, -1))
    Δ = exp(dt) * normcdf(iscall * d1) * iscall
    return Δ
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
function blsprice(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, FlagIsCall::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    iscall = ifelse(ChainRulesCore.@ignore_derivatives(FlagIsCall), 1, -1)
    Price = iscall * K * (S0_K * exp(dt) * normcdf(iscall * d1) - exp(-rt) * normcdf(iscall * (d1 - sigma_sqrtT)))
    return Price
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
function blkprice(F0::num1, K::num2, r::num3, T::num4, σ::num5, FlagIsCall::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(F0, K, r, T, σ))
    iscall = ifelse(ChainRulesCore.@ignore_derivatives(FlagIsCall), 1, -1)
    rt = r * T
    sigma_sqrtT = σ * sqrt(T)
    F0_K = F0 / K
    d1 = (log(F0_K)) / sigma_sqrtT + sigma_sqrtT / 2
    d2 = d1 - sigma_sqrtT
    Price = iscall * K * exp(-rt) * (F0_K * normcdf(iscall * d1) - normcdf(iscall * d2))
    return Price
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
function blsgamma(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, ::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    Γ = exp(dt) * normpdf(d1) / (S0 * sigma_sqrtT)
    return Γ
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
function blsvega(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, ::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
    rt = r * T
    dt = -d * T
    sqrtT = sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d1 = (log(S0 / K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    ν = S0 * exp(dt) * normpdf(d1) * sqrtT
    return ν
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
function blsrho(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, FlagIsCall::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
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
function blstheta(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, FlagIsCall::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
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
function blslambda(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, FlagIsCall::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
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

"Check input for Black Scholes Formula"
@inline function blscheck(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
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
function blspsi(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, FlagIsCall::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
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
function blsvanna(S0::num1, K::num2, r::num3, T::num4, σ::num5, d::num6 = 0, ::Bool = true) where {num1 <: Number, num2 <: Number, num3 <: Number, num4 <: Number, num5 <: Number, num6 <: Number}
    ChainRulesCore.@ignore_derivatives(FinancialToolbox.blscheck(S0, K, r, T, σ, d))
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / 2
    d2 = d1 - sigma_sqrtT
    Vanna = -exp(dt) * normpdf(d1) * d2 / σ
    return Vanna
end
