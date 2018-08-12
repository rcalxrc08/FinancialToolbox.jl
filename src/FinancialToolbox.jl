__precompile__()
module FinancialToolbox

	using SpecialFunctions: erf
	using Dates
	include("dates.jl");
	include("financial.jl")
	export
	    normcdf,
		normpdf,
		blsprice,
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
