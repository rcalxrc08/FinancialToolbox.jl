__precompile__()
module FinancialToolbox

	using SpecialFunctions: erf
	using Dates,Requires
	include("dates.jl");
	function __init__()
		@require DualNumbers = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74" include("financial_dual.jl")
		@require ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210" include("financial_fwd_diff.jl")
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
