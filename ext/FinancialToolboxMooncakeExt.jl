module FinancialToolboxMooncakeExt

using FinancialToolbox
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

end
