using .DualNumbers
value__d(x) = x.value
value__d(x::Real) = x

function blsimpv_impl(zero_typed::Dual,S0, K, r, T, price_d,d,FlagIsCall,xtol, ytol)
	f1(S0, K, r, T, x, d, FlagIsCall,price_d) =  price_d-blsprice(S0, K, r, T, x, d, FlagIsCall)
	f(x) = value__d(f1(S0, K, r, T, x, d, FlagIsCall,price_d))
	σ = FinancialToolbox.brentMethod(f, 0.001, 1.2, xtol, ytol)
	der_ = f1(S0, K, r, T, σ, d, FlagIsCall,price_d) / value__d(blsvega(S0, K, r, T, σ, d, FlagIsCall))
	out = σ+der_
	return out;
end
