module FinancialToolboxEnzymeCoreExt

using FinancialToolbox: blimpv, blimpv_sensitivities
using EnzymeCore: Annotation, Const, Active, Duplicated, BatchDuplicated
using EnzymeCore.EnzymeRules: EnzymeRules, FwdConfig, RevConfig, AugmentedReturn, needs_primal, needs_shadow, width

const FloatArg = Annotation{<:Base.IEEEFloat}

# Tangent(s) of an argument: zero for Const, a scalar for width 1, a tuple for batched forward mode
tangents(x::Const, ::Val{1}) = zero(x.val)
tangents(x::Const, ::Val{N}) where {N} = ntuple(_ -> zero(x.val), Val(N))
tangents(x::Annotation, ::Val) = x.dval

function EnzymeRules.forward(
    config::FwdConfig,
    ::Const{typeof(blimpv)},
    ::Type{<:Annotation},
    S0::FloatArg,
    K::FloatArg,
    T::FloatArg,
    Price::FloatArg,
    FlagIsCall::Annotation{Bool},
    xtol::FloatArg,
    n_iter_max::Annotation{Int},
)
    σ = blimpv(S0.val, K.val, T.val, Price.val, FlagIsCall.val, xtol.val, n_iter_max.val)
    needs_shadow(config) || return needs_primal(config) ? σ : nothing
    N = Val(width(config))
    der_S0, der_K, der_T, der_price = blimpv_sensitivities(S0.val, K.val, T.val, σ, FlagIsCall.val)
    dσ = map((dS0, dK, dT, dP) -> dS0 * der_S0 + dK * der_K + dT * der_T + dP * der_price, tangents(S0, N), tangents(K, N), tangents(T, N), tangents(Price, N))
    needs_primal(config) || return dσ
    return width(config) == 1 ? Duplicated(σ, dσ) : BatchDuplicated(σ, dσ)
end

function EnzymeRules.augmented_primal(
    config::RevConfig,
    ::Const{typeof(blimpv)},
    ::Type{<:Active},
    S0::FloatArg,
    K::FloatArg,
    T::FloatArg,
    Price::FloatArg,
    FlagIsCall::Annotation{Bool},
    xtol::FloatArg,
    n_iter_max::Annotation{Int},
)
    σ = blimpv(S0.val, K.val, T.val, Price.val, FlagIsCall.val, xtol.val, n_iter_max.val)
    return AugmentedReturn(needs_primal(config) ? σ : nothing, nothing, σ)
end

# In batched reverse mode dret is a tuple of Active cotangents, and each adjoint is returned as a tuple
cotangents(dret::Active) = dret.val
cotangents(dret::NTuple{N, Active}) where {N} = map(d -> d.val, dret)

function EnzymeRules.reverse(
    ::RevConfig,
    ::Const{typeof(blimpv)},
    dret::Union{Active, NTuple{N, Active} where {N}},
    σ,
    S0::FloatArg,
    K::FloatArg,
    T::FloatArg,
    Price::FloatArg,
    FlagIsCall::Annotation{Bool},
    xtol::FloatArg,
    n_iter_max::Annotation{Int},
)
    der_S0, der_K, der_T, der_price = blimpv_sensitivities(S0.val, K.val, T.val, σ, FlagIsCall.val)
    dσ = cotangents(dret)
    adjoint(x, der) = x isa Active ? map(d -> d * der, dσ) : nothing
    return (adjoint(S0, der_S0), adjoint(K, der_K), adjoint(T, der_T), adjoint(Price, der_price), nothing, adjoint(xtol, zero(xtol.val)), nothing)
end

end
