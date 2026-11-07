module FinancialToolboxMooncakeExt

using FinancialToolbox
using FinancialToolbox: blimpv, blprice_diff_impl, blvega_impl
using Mooncake
using Mooncake: @from_chainrules, DefaultCtx

# frule!! and rrule!! are derived from the ChainRulesCore rules of blimpv
@from_chainrules DefaultCtx Tuple{
    typeof(FinancialToolbox.blimpv),
    Base.IEEEFloat,
    Base.IEEEFloat,
    Base.IEEEFloat,
    Base.IEEEFloat,
    Bool,
    Base.IEEEFloat,
    Int,
}

# Same for the Black formula, whose derivatives are known in closed form
@from_chainrules DefaultCtx Tuple{typeof(FinancialToolbox.blprice_impl), Base.IEEEFloat, Base.IEEEFloat, Base.IEEEFloat, Base.IEEEFloat, Bool}

# Inside GPU broadcasts Mooncake does not use the rules above: it evaluates the broadcast function on its own forward
# mode dual numbers (Nfwd.NDual, a subtype of AbstractFloat, defined from Mooncake 0.5.x on). Without this method they
# would run through the Let's Be Rational solver, which does not compile for the GPU with them. As for ForwardDiff:
# σ is solved on the values, and σ + (price - blprice(σ)) / vega carries its derivatives (implicit function theorem).
@static if isdefined(Mooncake, :Nfwd) && isdefined(Mooncake.Nfwd, :NDual)
    const NDual = Mooncake.Nfwd.NDual
    primal_value(x::NDual) = x.value
    primal_value(x) = x
    function FinancialToolbox.blimpv_impl(::NDual, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
        S0_v, K_v, T_v = primal_value(S0), primal_value(K), primal_value(T)
        σ = blimpv(S0_v, K_v, T_v, primal_value(price_d), FlagIsCall, xtol, n_iter_max)
        return σ + blprice_diff_impl(S0, K, T, σ, price_d, FlagIsCall) / blvega_impl(S0_v, K_v, T_v, σ)
    end
end

end
