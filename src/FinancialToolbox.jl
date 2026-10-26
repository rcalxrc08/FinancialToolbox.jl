__precompile__()
module FinancialToolbox

using SpecialFunctions: erfc
using Dates, ChainRulesCore
include("dates.jl")
include("financial.jl")
include("financial_implied_volatility.jl")
include("financial_lets_be_rational.jl")
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
