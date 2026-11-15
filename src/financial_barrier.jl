# Barrier options under Black and Scholes, continuously monitored, without rebate. No new formula: by the reflection
# principle the price of a knock-out with barrier H is
#     V(S0) - (H / S0)^p V(H² / S0),    p = 2 (r - d) / σ² - 1,
# where V is the European price of the payoff restricted to the alive side of the barrier, a combination of blsprice and
# blsbin. The knock-ins follow from the in-out parity. No branches (Zygote is about 20 times slower on control flow):
# calls and puts differ by a 0/1 weight from call_put_sign, and the cases of the strike against the barrier are absorbed
# by max and min (the price is smooth at K = H, where the kink of max and min is multiplied by zero).

# Exponent of the reflection principle under Black and Scholes
barrier_image_exponent(r, σ, d) = muladd(two_internal, (r - d) / square(σ), minus_one_internal)

# max and min of the strike and the barrier. Complex numbers (complex step) compare by domain_value (the real part), as
# in the domain checks, without promoting the real one; every other number type has its own max and min (Symbolics
# builds a symbolic one).
barrier_max(a, b) = max(a, b)
barrier_min(a, b) = min(a, b)
for (A, B) in ((Complex, Complex), (Complex, Real), (Real, Complex))
    @eval barrier_max(a::$A, b::$B) = ifelse(domain_value(a) >= domain_value(b), a, b)
    @eval barrier_min(a::$A, b::$B) = ifelse(domain_value(a) <= domain_value(b), a, b)
end

# Price of the payoff (x - K) 1{x > z}, a call struck at z plus a binary paying z - K, and of (K - x) 1{x < z}
forward_above(S0, K, r, T, σ, d, z) = muladd(z - K, blsbin(S0, z, r, T, σ, d), blsprice(S0, z, r, T, σ, d))
forward_below(S0, K, r, T, σ, d, z) = muladd(K - z, blsbin(S0, z, r, T, σ, d, false), blsprice(S0, z, r, T, σ, d, false))

# European prices of the knock-out payoffs restricted to the alive side of the barrier. (K - x)⁺ = (x - K)⁺ - (x - K):
# above the barrier the put is the call minus (x - K) 1{x > H}, below it the call is the put minus (K - x) 1{x < H}
function downout_alive_price(S0, K, r, T, σ, d, H, FlagIsCall::Bool)
    minus_isput = (call_put_sign(FlagIsCall) - one_internal) ÷ two_internal # 0 for a call, -1 for a put
    return muladd(minus_isput, forward_above(S0, K, r, T, σ, d, H), forward_above(S0, K, r, T, σ, d, barrier_max(K, H)))
end
function upout_alive_price(S0, K, r, T, σ, d, H, FlagIsCall::Bool)
    minus_iscall = (minus_one_internal - call_put_sign(FlagIsCall)) ÷ two_internal # -1 for a call, 0 for a put
    return muladd(minus_iscall, forward_below(S0, K, r, T, σ, d, H), forward_below(S0, K, r, T, σ, d, barrier_min(K, H)))
end

"""
    blsdownout(S0, K, r, T, σ, d, H, FlagIsCall = true)

Price of a down-and-out European option in the Black and Scholes model: the option is knocked out if the underlying
ever goes below the barrier `H`, monitored continuously, without rebate.

# Arguments
- `S0`: spot price of the underlying, above the barrier.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `H`: barrier, positive and below `S0`.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blsdownout(10.0, 10.0, 0.01, 2.0, 0.2, 0.01, 8.0)
1.0349806169570723
```

See also [`blsdownin`](@ref), [`blsupout`](@ref), [`blsprice`](@ref).
"""
function blsdownout(S0, K, r, T, σ, d, H, FlagIsCall::Bool = true)
    check_positive(K, "Strike price must be positive")
    check_positive(H, "Barrier must be positive")
    check_positive(S0 - H, "Spot price must be above the barrier")
    p = barrier_image_exponent(r, σ, d)
    S0_image = square(H) / S0
    return muladd(-(H / S0)^p, downout_alive_price(S0_image, K, r, T, σ, d, H, FlagIsCall), downout_alive_price(S0, K, r, T, σ, d, H, FlagIsCall))
end

"""
    blsupout(S0, K, r, T, σ, d, H, FlagIsCall = true)

Price of an up-and-out European option in the Black and Scholes model: the option is knocked out if the underlying
ever goes above the barrier `H`, monitored continuously, without rebate.

# Arguments
- `S0`: spot price of the underlying, below the barrier.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `H`: barrier, above `S0`.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blsupout(10.0, 10.0, 0.01, 2.0, 0.2, 0.01, 12.0, false)
0.9741004570291205
```

See also [`blsupin`](@ref), [`blsdownout`](@ref), [`blsprice`](@ref).
"""
function blsupout(S0, K, r, T, σ, d, H, FlagIsCall::Bool = true)
    check_positive(K, "Strike price must be positive")
    check_positive(H, "Barrier must be positive")
    check_positive(H - S0, "Spot price must be below the barrier")
    p = barrier_image_exponent(r, σ, d)
    S0_image = square(H) / S0
    return muladd(-(H / S0)^p, upout_alive_price(S0_image, K, r, T, σ, d, H, FlagIsCall), upout_alive_price(S0, K, r, T, σ, d, H, FlagIsCall))
end

"""
    blsdownin(S0, K, r, T, σ, d, H, FlagIsCall = true)

Price of a down-and-in European option in the Black and Scholes model: the option is activated if the underlying
ever goes below the barrier `H`, monitored continuously, without rebate. It is the European option minus the
down-and-out one.

# Arguments
- `S0`: spot price of the underlying, above the barrier.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `H`: barrier, positive and below `S0`.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blsdownin(10.0, 10.0, 0.01, 2.0, 0.2, 0.01, 8.0, false)
1.005956123316791
```

See also [`blsdownout`](@ref), [`blsupin`](@ref), [`blsprice`](@ref).
"""
function blsdownin(S0, K, r, T, σ, d, H, FlagIsCall::Bool = true)
    return blsprice(S0, K, r, T, σ, d, FlagIsCall) - blsdownout(S0, K, r, T, σ, d, H, FlagIsCall)
end

"""
    blsupin(S0, K, r, T, σ, d, H, FlagIsCall = true)

Price of an up-and-in European option in the Black and Scholes model: the option is activated if the underlying
ever goes above the barrier `H`, monitored continuously, without rebate. It is the European option minus the
up-and-out one.

# Arguments
- `S0`: spot price of the underlying, below the barrier.
- `K`: strike price.
- `r`: continuously compounded zero rate.
- `T`: time to maturity, in years.
- `σ`: implied volatility.
- `d`: continuously compounded dividend yield of the underlying.
- `H`: barrier, above `S0`.
- `FlagIsCall`: `true` for a call, `false` for a put.

# Example
```jldoctest
julia> blsupin(10.0, 10.0, 0.01, 2.0, 0.2, 0.01, 12.0)
1.0537786287548607
```

See also [`blsupout`](@ref), [`blsdownin`](@ref), [`blsprice`](@ref).
"""
function blsupin(S0, K, r, T, σ, d, H, FlagIsCall::Bool = true)
    return blsprice(S0, K, r, T, σ, d, FlagIsCall) - blsupout(S0, K, r, T, σ, d, H, FlagIsCall)
end
