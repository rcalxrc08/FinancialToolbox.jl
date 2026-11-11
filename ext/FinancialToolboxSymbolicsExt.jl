module FinancialToolboxSymbolicsExt

using Symbolics
using FinancialToolbox: blimpv_sensitivities
import FinancialToolbox: blimpv, domain_value

# symbolic values are not checked (the numeric arguments still are)
domain_value(::Num) = nothing

@register_symbolic blimpv(S0, K, T, Price, FlagIsCall::Bool, xtol::Float64, n_iter_max::Int64)

# Arguments arrive unwrapped (constants included): rebuild σ on Num and reuse the closed-form sensitivities.
Symbolics.@register_derivative blimpv(S0, K, T, Price, FlagIsCall, xtol, n_iter_max) I begin
    if I > 4
        return Symbolics.SConst(0)
    end
    FlagIsCall_r = Symbolics.unwrap_const(FlagIsCall)
    S0_n, K_n, T_n, Price_n = Symbolics.wrap(S0), Symbolics.wrap(K), Symbolics.wrap(T), Symbolics.wrap(Price)
    σ = blimpv(S0_n, K_n, T_n, Price_n, FlagIsCall_r, Symbolics.unwrap_const(xtol), Symbolics.unwrap_const(n_iter_max))
    return Symbolics.unwrap(blimpv_sensitivities(S0_n, K_n, T_n, σ, FlagIsCall_r)[I])
end

end
