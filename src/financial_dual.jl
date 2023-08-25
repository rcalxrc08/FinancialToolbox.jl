using .DualNumbers
value__d(x) = x.value
value__d(x::Real) = x

function blsimpv_impl(zero_typed::Dual,S0, K, r, T, price_d,d,FlagIsCall,xtol, ytol)
    S0_r=value__d(S0)
	K_r=value__d(K)
	r_r=value__d(r)
	T_r=value__d(T)
	p_r=value__d(price_d)
	d_r=value__d(d)
	sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r, FlagIsCall, xtol, ytol)
	der_ = (price_d-blsprice(S0, K, r, T, sigma, d, FlagIsCall)) / blsvega(S0_r, K_r, r_r, T_r, sigma, d_r, FlagIsCall)
	out = sigma+der_
	return out;
end
