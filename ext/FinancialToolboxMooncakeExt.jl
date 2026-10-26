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

end
