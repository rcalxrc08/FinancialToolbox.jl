using .TaylorSeries
function FinancialToolbox.normcdf(x::Taylor1)
	out=zero(x)
	@inbounds @views out[0] = FinancialToolbox.normcdf(x[0])
	ders_t=FinancialToolbox.normpdf(x);
	x_der=derivative(x,1);
	#Faa di Bruno
	prev_der=ders_t*x_der
	@views out[1]=prev_der[0]
	lout=get_order(out)-1
	for i in 1:lout
		prev_der=derivative(prev_der,1)
		if(i<20)
			@views out[i+1]=prev_der[0]/factorial(i+1)
		else
			@views out[i+1]=Float64(prev_der[0]/factorial(big(i+1)))
		end
	end
	return out;
end
# TODO: move to proper implementation: https://github.com/JuliaDiff/TaylorSeries.jl/issues/285
function FinancialToolbox.normcdf(x::TaylorN)
	Nmax=20000
	xmin=-5.0
	x_=range(xmin,length=Nmax,stop=x)
	dx=(x-xmin)/(Nmax-1);
	return sum(FinancialToolbox.normpdf.(x_))*dx;
end


!hasmethod(isless,(Taylor1,Taylor1)) ? (Base.isless(x::Taylor1,y::Taylor1)=x[0]<y[0]) : nothing
!hasmethod(isless,(TaylorN,TaylorN)) ? (Base.isless(x::TaylorN,y::TaylorN)=x[0][1]<y[0][1]) : nothing
# function FinancialToolbox.normcdf(x::Taylor1)
	# ders_t=FinancialToolbox.normpdf(x);
	# x_der=derivative(x,1);
	# return integrate(ders_t*x_der,FinancialToolbox.normcdf(x[0]));;
# end

# # The following function has been generated by using Symbolics.jl and applying some additional flow control.
# function normcdf2(x::Taylor1)
	# return integrate(normpdf2(x),FinancialToolbox.normcdf(x[0]));
# end