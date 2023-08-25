using .HyperDualNumbers

value__d(x::Hyper) = x.value
value__d(x) = x

function blsimpv_impl(zero_typed::Hyper,S0, K, r, T, price_d,d,FlagIsCall,xtol, ytol)
	S0_r=value__d(S0)
	K_r=value__d(K)
	r_r=value__d(r)
	T_r=value__d(T)
	p_r=value__d(price_d)
	d_r=value__d(d)
	sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r,FlagIsCall,xtol, ytol)
	der_ = (price_d-blsprice(S0, K, r, T, sigma, d,FlagIsCall)) / blsvega(S0_r, K_r, r_r, T_r, sigma, d_r)
	out = sigma+der_
	return out;
end


# function blsimpv2(S0, K, r, T, price_d,d,FlagIsCall,xtol, ytol)
	# f_(x) = price_d-blsprice(S0, K, r, T, x, d, FlagIsCall)
	# σ = FinancialToolbox.brentMethod(x->f_(hyper(x)).value, 0.001, 1.2, xtol, ytol)
	# σ_der1 = FinancialToolbox.brentMethod(x->f_( hyper(σ,x,0.0,0.0)).epsilon1, -2.0, 1.2, 1e-15, 1e-15)
	# σ_der2 = FinancialToolbox.brentMethod(x->f_( hyper(σ,σ_der1,x,0.0)).epsilon2, -2.0, 1.2, 1e-15, 1e-15)
	# σ_der12 = FinancialToolbox.brentMethod(x->f_( hyper(σ,σ_der1,σ_der2,x)).epsilon12, -2.0, 1.2, 1e-15, 1e-15)
	# return hyper(σ,σ_der1,σ_der2,σ_der12);
# end
# function blsimpv2(S0, K, r, T, price_d,d)
	# S0_r=value__d(S0)
	# K_r=value__d(K)
	# r_r=value__d(r)
	# T_r=value__d(T)
	# p_r=value__d(price_d)
	# d_r=value__d(d)
	# sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r)
	# der_ = (price_d-blsprice(S0, K, r, T, sigma, d)) / blsvega(S0_r, K_r, r_r, T_r, sigma, d_r)
	# out = sigma+der_
	# return out;
# end