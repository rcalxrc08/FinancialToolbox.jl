module FinancialToolboxMooncakeExt

using FinancialToolbox
using Mooncake
using Mooncake: @is_primitive, DefaultCtx, CoDual, NoRData, NoFData, ZeroRData

@is_primitive DefaultCtx Tuple{
    typeof(FinancialToolbox.blimpv),
    Base.IEEEFloat,
    Base.IEEEFloat,
    Base.IEEEFloat,
    Base.IEEEFloat,
    Bool,
    Base.IEEEFloat,
    Int,
}

function Mooncake.rrule!!(
    ::CoDual{typeof(FinancialToolbox.blimpv)},
    S0::CoDual{<:Real},
    K::CoDual{<:Real},
    T::CoDual{<:Real},
    Price::CoDual{<:Real},
    FlagIsCall::CoDual{Bool},
    xtol::CoDual{<:Real},
    n_iter_max::CoDual{Int},
)
    S0p = Mooncake.primal(S0)
    Kp = Mooncake.primal(K)
    Tp = Mooncake.primal(T)
    Pricep = Mooncake.primal(Price)
    FlagIsCallp = Mooncake.primal(FlagIsCall)
    xtolp = Mooncake.primal(xtol)
    n_iter_maxp = Mooncake.primal(n_iter_max)

    σ = FinancialToolbox.blimpv(S0p, Kp, Tp, Pricep, FlagIsCallp, xtolp, n_iter_maxp)
    y = CoDual(σ, NoFData())

    function pb!!(y_rdata)
        if y_rdata isa NoRData
            return (
                NoRData(),
                NoRData(),
                NoRData(),
                NoRData(),
                NoRData(),
                NoRData(),
                NoRData(),
                NoRData(),
            )
        end

        price_f(S0_, K_, T_, σ_) = FinancialToolbox.blprice(S0_, K_, T_, σ_, FlagIsCallp)
        cache = Mooncake.prepare_gradient_cache(price_f, S0p, Kp, Tp, σ; config=Mooncake.Config())
        _, grad = Mooncake.value_and_gradient!!(cache, price_f, S0p, Kp, Tp, σ)

        @views dS0 = grad[2]
        @views dK = grad[3]
        @views dT = grad[4]
        @views dσ = grad[5]
        scale = y_rdata / dσ

        return (
            NoRData(),
            -scale * dS0,
            -scale * dK,
            -scale * dT,
            scale,
            NoRData(),
            ZeroRData(),
            NoRData(),
        )
    end

    return y, pb!!
end


end
