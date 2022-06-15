using .TaylorSeries
function FinancialToolbox.normcdf(x::Taylor1)
	out=zero(x)
	@inbounds @views out[0] = FinancialToolbox.normcdf(x[0])
	lout=get_order(out)-1
	if(get_order(out)==0)
		return out;
	end
	ders_t=FinancialToolbox.normpdf(x);
	x_der=derivative(x,1);
	#Faa di Bruno
	prev_der=ders_t*x_der
	@views out[1]=prev_der[0]
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



function blsimpv_impl(zero_typed::Taylor1,S0, K, r, T, price_d,d,FlagIsCall,xtol, ytol)
	f_order(x,order) =  getcoeff(price_d-blsprice(S0, K, r, T, x, d, FlagIsCall),order)
	zero_type=S0* K* r* T* d*price_d*0
	max_order=get_order(zero_type)
	σ_coeffs=Float64[];
	σ = FinancialToolbox.brentMethod(x->f_order(Taylor1([x]),0), 0.001, 1.2, 1e-6, 1e-6)
	append!(σ_coeffs,σ)
	for i in 1:max_order
		σ_der = FinancialToolbox.brentMethod(x->f_order(Taylor1([σ_coeffs...,x]),i), -6000.0, 600.2, 1e-15, 1e-15)
		append!(σ_coeffs,σ_der)
	end
	return Taylor1(σ_coeffs);
end

function blsimpv_impl(zero_typed::TaylorN,S0, K, r, T, price_d,d,FlagIsCall,xtol, ytol)
	f_order(x,order,order2) =  (price_d-blsprice(S0, K, r, T, x, d, FlagIsCall))[order][order2]
	zero_type=S0* K* r* T* d*price_d*0
	max_order=get_order(zero_type)
	σ_coeffs=Array{Array{Float64}}(undef,0);
	σ = FinancialToolbox.brentMethod(x->f_order(TaylorN(HomogeneousPolynomial(x,0)),0,1), 0.001, 1.2, 1e-6, 1e-6)
	append!(σ_coeffs,[[σ]])
	for i in 1:max_order
		curr_=TaylorN(HomogeneousPolynomial.(σ_coeffs))
		inner_order=length(zero_type[i])
		cur_level_σ_coeffs=zeros(inner_order);
		for j in 1:inner_order
			@show i,j
			σ_der = FinancialToolbox.brentMethod(x->f_order(curr_+TaylorN(HomogeneousPolynomial(setindex!(cur_level_σ_coeffs,x,j))),i,j), -2.0, 1.2, 1e-6, 1e-6)
			# @show σ_der
			#append!(cur_level_σ_coeffs,σ_der)
			# @show cur_level_σ_coeffs
			# @show j
			setindex!(cur_level_σ_coeffs,σ_der,j)
		end	
		push!(σ_coeffs,cur_level_σ_coeffs)
	end
	return TaylorN(σ_coeffs);
end