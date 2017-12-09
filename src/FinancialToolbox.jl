__precompile__()
module FinancialToolbox

	if (VERSION.major==0&&VERSION.minor>=6)
		using SpecialFunctions.erf
	end
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
