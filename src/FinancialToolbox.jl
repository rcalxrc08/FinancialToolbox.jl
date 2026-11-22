__precompile__()
module FinancialToolbox

using SpecialFunctions: erfc
using Dates, ChainRulesCore
include("01_dates/dates.jl")
include("02_pricing/financial.jl")
include("03_barriers/financial_barrier.jl")
include("04_implied_volatility/financial_implied_volatility.jl")
include("04_implied_volatility/financial_lets_be_rational.jl")
include("05_value_and_partials/financial_value_and_partials.jl")
export normcdf,
    normpdf,
    blsprice,
    blsbin,
    blsdownout,
    blsdownin,
    blsupout,
    blsupin,
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
