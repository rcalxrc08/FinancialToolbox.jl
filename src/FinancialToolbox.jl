__precompile__()
module FinancialToolbox

using SpecialFunctions: erfc
using Dates, Requires, ChainRulesCore
include("dates.jl")
include("financial.jl")
include("financial_implied_volatility.jl")
include("financial_lets_be_rational.jl")
function __init__()
    @require DualNumbers = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74" include("financial_dual.jl")
    @require ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210" include("financial_forward_diff.jl")
    @require ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267" include("financial_reverse_diff.jl")
    @require HyperDualNumbers = "50ceba7f-c3ee-5a84-a6e8-3ad40456ec97" include("financial_hyper.jl")
    @require TaylorSeries = "6aa5eb33-94cf-58f4-a9d0-e4b2c4fc25ea" include("financial_taylor.jl")
end
export normcdf,
    normpdf,
    blsprice,
    blsbin,
    blkprice,
    blsdelta,
    blsgamma,
    blsvega,
    blsrho,
    blstheta,
    blslambda,
    blsimpv,
    blkimpv,
    ##	ADDITIONAL Function
    blspsi,
    blsvanna,
    #Dates
    fromExcelNumberToDate,
    daysact,
    yearfrac

end#End Module
