module FinancialToolboxHyperDualNumbersExt

using HyperDualNumbers
using FinancialToolbox: blimpv, blprice_diff_impl, blprice_impl, blvega_impl
import FinancialToolbox: blimpv_impl, normcdf, normpdf, internal_sqrt

# normcdf through erfc, and sqrt, would promote Hyper{Float32} to Hyper{Float64} (Float64 constants in the derivative rules of
# HyperDualNumbers). f(a + b ε₁ + c ε₂ + d ε₁ε₂) = f(a) + f'(a) (b ε₁ + c ε₂ + d ε₁ε₂) + f''(a) b c ε₁ε₂, with
# normcdf' = normpdf and normcdf'' = -x normpdf.
function normcdf(x::Hyper)
    a = HyperDualNumbers.value(x)
    φ = normpdf(a)
    return Hyper(normcdf(a), φ * eps1(x), φ * eps2(x), φ * (eps1eps2(x) - a * eps1(x) * eps2(x)))
end
# sqrt' = 1 / (2 √a), sqrt'' = -1 / (4 a √a)
function internal_sqrt(x::Hyper)
    a = HyperDualNumbers.value(x)
    root = sqrt(a)
    d1 = inv(2 * root)
    return Hyper(root, d1 * eps1(x), d1 * eps2(x), d1 * eps1eps2(x) - eps1(x) * eps2(x) / (4 * a * root))
end

function blimpv_impl(::Type{<:Hyper}, S0, K, T, price_d, FlagIsCall, xtol, n_iter_max)
    S0_r = HyperDualNumbers.value(S0)
    K_r = HyperDualNumbers.value(K)
    T_r = HyperDualNumbers.value(T)
    pr_r = HyperDualNumbers.value(price_d)
    σ = blimpv(S0_r, K_r, T_r, pr_r, FlagIsCall, xtol, n_iter_max)
    vega = blvega_impl(S0_r, K_r, T_r, σ)
    σ_hyper = σ + blprice_diff_impl(S0, K, T, σ, price_d, FlagIsCall) / vega
    σ_hyper -= Hyper(0, 0, 0, HyperDualNumbers.eps1eps2(σ_hyper))
    σ_hyper += (price_d - blprice_impl(S0, K, T, σ_hyper, FlagIsCall)) / vega
    return σ_hyper
end

end
