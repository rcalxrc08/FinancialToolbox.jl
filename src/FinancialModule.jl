__precompile__()
module FinancialModule

	if (VERSION.major==0&&VERSION.minor>=6)
		using SpecialFunctions.erf
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
		blsvanna



end#End Module
