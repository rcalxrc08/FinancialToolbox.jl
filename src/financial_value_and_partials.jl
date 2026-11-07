# value_and_partials(f, inputs..., parameters): the value of f and its partial derivatives with respect to the inputs,
# in closed form. Used by the ReverseDiff extension (one tape instruction per call) and by the ChainRules rules of the
# broadcasts below. `parameters` is FlagIsCall for the pricers and (FlagIsCall, xtol, n_iter_max) for the implied
# volatilities.

# Black formula: partials with respect to S0, K, T and σ
value_and_partials(::typeof(blprice_impl), S0, K, T, σ, FlagIsCall) = let (Price, partials...) = blprice_and_sensitivities(S0, K, T, σ, FlagIsCall)
    Price, partials
end

# blsprice = blprice(F, K, T, σ) / cv with F = S0 e^((r - d) T) and cv = e^(r T)
function value_and_partials(::typeof(blsprice), S0, K, r, T, σ, d, FlagIsCall)
    inv_cv = exp(-r * T)
    F = S0 * exp((r - d) * T)
    blcheck(F, K, T, σ)
    B, ∂F, ∂K, ∂T, ∂σ = blprice_and_sensitivities(F, K, T, σ, FlagIsCall)
    Price = B * inv_cv
    F∂F = F * ∂F * inv_cv
    return Price, (F∂F / S0, ∂K * inv_cv, T * (F∂F - Price), muladd(r - d, F∂F, ∂T * inv_cv) - r * Price, ∂σ * inv_cv, -T * F∂F)
end

# blkprice = blprice(F0, K, T, σ) / cv with cv = e^(r T)
function value_and_partials(::typeof(blkprice), F0, K, r, T, σ, FlagIsCall)
    inv_cv = exp(-r * T)
    blcheck(F0, K, T, σ)
    B, ∂F, ∂K, ∂T, ∂σ = blprice_and_sensitivities(F0, K, T, σ, FlagIsCall)
    Price = B * inv_cv
    return Price, (∂F * inv_cv, ∂K * inv_cv, -T * Price, muladd(∂T, inv_cv, -r * Price), ∂σ * inv_cv)
end

# Implied volatility of the Black formula: partials with respect to S0, K, T and the price
function value_and_partials(::typeof(blimpv), S0, K, T, price_d, (FlagIsCall, xtol, n_iter_max))
    σ = blimpv(S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    return σ, blimpv_sensitivities(S0, K, T, σ, FlagIsCall)
end

# blsimpv = blimpv(S0 e^((r - d) T), K, T, Price e^(r T))
function value_and_partials(::typeof(blsimpv), S0, K, r, T, Price, d, (FlagIsCall, xtol, n_iter_max))
    cv = exp(r * T)
    F = S0 * cv * exp(-d * T)
    adj_price = Price * cv
    σ = blimpv(F, K, T, adj_price, FlagIsCall, xtol, n_iter_max)
    ∂F, ∂K, ∂T, ∂price = blimpv_sensitivities(F, K, T, σ, FlagIsCall)
    F∂F = F * ∂F
    P∂P = adj_price * ∂price
    return σ, (F∂F / S0, ∂K, T * (F∂F + P∂P), ∂T + muladd(r - d, F∂F, r * P∂P), ∂price * cv, -T * F∂F)
end

# blkimpv = blimpv(F0, K, T, Price e^(r T))
function value_and_partials(::typeof(blkimpv), F0, K, r, T, Price, (FlagIsCall, xtol, n_iter_max))
    cv = exp(r * T)
    adj_price = Price * cv
    σ = blimpv(F0, K, T, adj_price, FlagIsCall, xtol, n_iter_max)
    ∂F, ∂K, ∂T, ∂price = blimpv_sensitivities(F0, K, T, σ, FlagIsCall)
    P∂P = adj_price * ∂price
    return σ, (∂F, ∂K, T * P∂P, muladd(r, P∂P, ∂T), ∂price * cv)
end

# Broadcasts of the pricers and of the implied volatilities, as in a calibration over many options: one fused pass
# computes the values and all the partials, and the pullback multiplies them by the cotangent. Without these rules
# Zygote differentiates a broadcast per element on the CPU and, on GPUs, reruns the whole broadcast once per argument
# with dual numbers (an implied volatility solve per argument). Each partial is a thunk: the gradients of arguments
# that are not differentiated (constants of a closure) are never computed.
broadcast_value_and_partials(::typeof(blsprice), S0, K, r, T, σ, d, FlagIsCall::Bool = true) = flatten_value_and_partials(value_and_partials(blsprice, S0, K, r, T, σ, d, FlagIsCall))
broadcast_value_and_partials(::typeof(blkprice), F0, K, r, T, σ, FlagIsCall::Bool = true) = flatten_value_and_partials(value_and_partials(blkprice, F0, K, r, T, σ, FlagIsCall))
broadcast_value_and_partials(::typeof(blsimpv), S0, K, r, T, Price, d, FlagIsCall::Bool = true, xtol::Real = default_xtol(100 * eps(Float64), S0, K, r, T, Price, d), n_iter_max::Integer = 4) = flatten_value_and_partials(value_and_partials(blsimpv, S0, K, r, T, Price, d, (FlagIsCall, xtol, n_iter_max)))
broadcast_value_and_partials(::typeof(blkimpv), F0, K, r, T, Price, FlagIsCall::Bool = true, xtol::Real = default_xtol(1e-14, F0, K, r, T, Price), n_iter_max::Integer = 4) = flatten_value_and_partials(value_and_partials(blkimpv, F0, K, r, T, Price, (FlagIsCall, xtol, n_iter_max)))
flatten_value_and_partials((value, partials)) = (value, partials...)

# The gradient of a broadcast argument: summed over the dimensions it was broadcast along
reduce_to_argument(::Number, g) = sum(g)
function reduce_to_argument(x::AbstractArray, g)
    size(x) == size(g) && return g
    dims = Tuple(filter(i -> size(x, i) == 1 && size(g, i) != 1, 1:ndims(g)))
    return reshape(sum(g; dims = dims), size(x))
end

const RealOrRealArray = Union{Real, AbstractArray{<:Real}}

for (f, n_inputs) in ((:blsprice, 6), (:blkprice, 5), (:blsimpv, 6), (:blkimpv, 5))
    inputs = [Symbol(:x, i) for i = 1:n_inputs]
    typed_inputs = [:($x::RealOrRealArray) for x in inputs]
    @eval function ChainRulesCore.rrule(config::ChainRulesCore.RuleConfig{>:ChainRulesCore.HasReverseMode}, ::typeof(Broadcast.broadcasted), ::typeof($f), $(typed_inputs...), parameters...)
        results = broadcast_value_and_partials.($f, $(inputs...), parameters...)
        values = first.(results)
        function broadcast_pullback(Δ)
            Δ = ChainRulesCore.unthunk(Δ)
            partial(i, x) = ChainRulesCore.@thunk reduce_to_argument(x, Δ .* getindex.(results, i + 1))
            return (ChainRulesCore.NoTangent(), ChainRulesCore.NoTangent(), $([:(partial($i, $x)) for (i, x) in enumerate(inputs)]...), map(_ -> ChainRulesCore.NoTangent(), parameters)...)
        end
        return values, broadcast_pullback
    end
end
