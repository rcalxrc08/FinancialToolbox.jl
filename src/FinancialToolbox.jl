__precompile__()
module FinancialToolbox

	using SpecialFunctions: erf
	using Dates,Requires
	include("dates.jl");
	function __init__()
		@require DualNumbers = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74" include("financial_dual.jl")
	end
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
