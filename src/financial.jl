using IrrationalConstants
const one_internal = Int8(1)
const minus_one_internal = Int8(-1)
const two_internal = Int8(2)
# ±1 for calls and puts. Declared non differentiable rather than wrapped in @ignore_derivatives at the call site,
# which costs Zygote tens of microseconds per call.
call_put_sign(FlagIsCall::Bool) = ifelse(FlagIsCall, one_internal, minus_one_internal)
ChainRulesCore.@non_differentiable call_put_sign(::Bool)
# sqrt of the maturity. Plain sqrt; the extensions of DualNumbers and HyperDualNumbers add methods that keep the
# element type, since their own sqrt promotes Float32 to Float64 (Float64 constants in their derivative rules).
internal_sqrt(x) = sqrt(x)
"""
    normcdf(x)

Cumulative distribution function of a standard Gaussian random variable at `x`, computed with `erfc`.

# Arguments
- `x`: point of evaluation, of any number type supported by the package.

# Example
```jldoctest
julia> normcdf(0.0)
0.5
```
"""
function normcdf(x)
    return erfc(-x * invsqrt2) / two_internal
end

"""
    normpdf(x)

Probability density function of a standard Gaussian random variable at `x`.

# Arguments
- `x`: point of evaluation, of any number type supported by the package.

# Example
```jldoctest
julia> normpdf(0.0)
0.3989422804014327
```
"""
function normpdf(x)
    return exp(x^2 / (-two_internal)) * invsqrt2π
end

"""
    blsbin(S0, K, r, T, σ, d, FlagIsCall = true)

Price of a binary (cash-or-nothing) European option paying 1 in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blsbin(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
0.4349813361147117
```
"""
function blsbin(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sqrtT = internal_sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d2 = (log(S0 / K) + rt + dt) / sigma_sqrtT - sigma_sqrtT / two_internal
    iscall = call_put_sign(FlagIsCall)
    Price = exp(-rt) * normcdf(iscall * d2)
    return Price
end

"""
    blsdelta(S0, K, r, T, σ, d, FlagIsCall = true)

Delta, the derivative of the price with respect to `S0`, of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blsdelta(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
0.5452173371920436
```

See also [`blsprice`](@ref).
"""
function blsdelta(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * internal_sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    iscall = call_put_sign(FlagIsCall)
    Δ = exp(dt) * normcdf(iscall * d1) * iscall
    return Δ
end

function blprice_impl(S0, K, T, σ, FlagIsCall::Bool = true)
    iscall = call_put_sign(FlagIsCall)
    sigma_sqrtT = σ * internal_sqrt(T)
    d1 = log(S0 / K) / sigma_sqrtT + sigma_sqrtT / two_internal
    Price = iscall * (S0 * normcdf(iscall * d1) - K * normcdf(iscall * (d1 - sigma_sqrtT)))
    return Price
end

# Price of blprice_impl and its closed form partial derivatives with respect to S0, K, T and σ:
# ∂S0 = ±N(±d1), ∂K = ∓N(±d2), ∂σ = S0 φ(d1) √T (vega) and ∂T = vega σ / (2T)
function blprice_and_sensitivities(S0, K, T, σ, FlagIsCall::Bool)
    iscall = call_put_sign(FlagIsCall)
    sqrtT = internal_sqrt(T)
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

function ChainRulesCore.frule((_, dS0, dK, dT, dσ, _)::Tuple, ::typeof(blprice_impl), S0, K, T, σ, FlagIsCall::Bool)
    Price, der_S0, der_K, der_T, der_σ = blprice_and_sensitivities(S0, K, T, σ, FlagIsCall)
    return Price, dS0 * der_S0 + dK * der_K + dT * der_T + dσ * der_σ
end

function blprice(S0, K, T, σ, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    return blprice_impl(S0, K, T, σ, FlagIsCall)
end
"""
    blsprice(S0, K, r, T, σ, d, FlagIsCall = true)

Price of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blsprice(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
1.102360010773319

julia> blsprice(10.0, 10.0, 0.01, 2.0, 0.2, 0.01, false)
1.102360010773319
```

See also [`blkprice`](@ref), [`blsimpv`](@ref).
"""
function blsprice(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    cv = exp(r * T)
    cv2 = exp((r - d) * T)
    F = S0 * cv2
    return blprice(F, K, T, σ, FlagIsCall) / cv
end
"""
    blkprice(F0, K, r, T, σ, FlagIsCall = true)

Price of a European option on a forward in the Black model.

# Arguments
- `F0`: forward price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blkprice(10.0, 10.0, 0.01, 2.0, 0.2)
1.102360010773319
```

See also [`blsprice`](@ref), [`blkimpv`](@ref).
"""
function blkprice(F0, K, r, T, σ, FlagIsCall::Bool = true)
    cv = exp(r * T)
    return blprice(F0, K, T, σ, FlagIsCall) / cv
end
"""
    blsgamma(S0, K, r, T, σ, d, FlagIsCall = true)

Gamma, the second derivative of the price with respect to `S0`, of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put; the gamma is the same for both.

# Example
```jldoctest
julia> blsgamma(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
0.1368788153571282
```

See also [`blsprice`](@ref).
"""
function blsgamma(S0, K, r, T, σ, d, ::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * internal_sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    Γ = exp(dt) * normpdf(d1) / (S0 * sigma_sqrtT)
    return Γ
end
function blvega_impl(S0, K, T, σ)
    sqrtT = internal_sqrt(T)
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
    blsvega(S0, K, r, T, σ, d, FlagIsCall = true)

Vega, the derivative of the price with respect to `σ`, of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put; the vega is the same for both.

# Example
```jldoctest
julia> blsvega(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
5.47515261428513
```

See also [`blsprice`](@ref).
"""
function blsvega(S0, K, r, T, σ, d, ::Bool = true)
    cv = exp(r * T)
    cv2 = exp(-d * T)
    F = S0 * cv * cv2
    return blvega(F, K, T, σ) / cv
end

"""
    blsrho(S0, K, r, T, σ, d, FlagIsCall = true)

Rho, the derivative of the price with respect to `r`, of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blsrho(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
8.699626722294234
```

See also [`blsprice`](@ref).
"""
function blsrho(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    iscall = call_put_sign(FlagIsCall)
    rt = r * T
    dt = -d * T
    sqrtT = internal_sqrt(T)
    sigma_sqrtT = σ * sqrtT
    d2 = (log(S0 / K) + rt + dt) / sigma_sqrtT - sigma_sqrtT / two_internal
    ρ = iscall * K * exp(-rt) * normcdf(iscall * d2) * T
    return ρ
end

"""
    blstheta(S0, K, r, T, σ, d, FlagIsCall = true)

Theta, minus the derivative of the price with respect to `T`, of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blstheta(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
-0.2627340306065233
```

See also [`blsprice`](@ref).
"""
function blstheta(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sqrtT = internal_sqrt(T)
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
    blslambda(S0, K, r, T, σ, d, FlagIsCall = true)

Lambda, the elasticity `Δ S0 / price`, of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blslambda(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
4.945909973725978
```

See also [`blsprice`](@ref).
"""
function blslambda(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * internal_sqrt(T)
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

# Domain checks, argument by argument. domain_value is the value compared with zero: the real part of a complex number
# (complex step), the constant term of a Taylor series (extension); nothing skips the check (symbolic values, extension).
# Dual numbers compare by their values. The messages are constant strings (GPU kernels).
domain_value(x) = x
domain_value(x::Complex) = real(x)

@inline function check_positive(x, message::String)
    v = domain_value(x)
    if !(v === nothing) && v <= zero(v)
        throw(DomainError(x, message))
    end
    return
end

function blcheck(S0, K, T)
    check_positive(S0, "Spot price must be positive")
    check_positive(K, "Strike price must be positive")
    check_positive(T, "Time to maturity must be positive")
    return
end
function blcheck(S0, K, T, σ)
    blcheck(S0, K, T)
    check_positive(σ, "Volatility must be positive")
    return
end
# Domain checks only (see call_put_sign)
ChainRulesCore.@non_differentiable blcheck(::Any, ::Any, ::Any)
ChainRulesCore.@non_differentiable blcheck(::Any, ::Any, ::Any, ::Any)
##	ADDITIONAL Functions

"""
    blspsi(S0, K, r, T, σ, d, FlagIsCall = true)

Psi, the derivative of the price with respect to `d`, of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blspsi(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
-10.904346743840872
```

See also [`blsprice`](@ref).
"""
function blspsi(S0, K, r, T, σ, d, FlagIsCall::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * internal_sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    iscall = call_put_sign(FlagIsCall)
    Ψ = -iscall * S0 * exp(dt) * normcdf(iscall * d1) * T
    return Ψ
end

"""
    blsvanna(S0, K, r, T, σ, d, FlagIsCall = true)

Vanna, the derivative of the delta with respect to `σ`, of a European option in the Black and Scholes model.

# Arguments
- `S0`: spot price of the underlying.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `FlagIsCall`: `true` for a call, `false` for a put; the vanna is the same for both.

# Example
```jldoctest
julia> blsvanna(10.0, 10.0, 0.01, 2.0, 0.2, 0.01)
0.2737576307142565
```

See also [`blsprice`](@ref).
"""
function blsvanna(S0, K, r, T, σ, d, ::Bool = true)
    blcheck(S0, K, T, σ)
    rt = r * T
    dt = -d * T
    sigma_sqrtT = σ * internal_sqrt(T)
    S0_K = S0 / K
    d1 = (log(S0_K) + rt + dt) / sigma_sqrtT + sigma_sqrtT / two_internal
    d2 = d1 - sigma_sqrtT
    Vanna = -exp(dt) * normpdf(d1) * d2 / σ
    return Vanna
end
