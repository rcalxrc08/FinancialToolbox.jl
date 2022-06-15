using .HyperDualNumbers

function blsimpv_impl(zero_typed::Hyper,S0, K, r, T, price_d,d,FlagIsCall,xtol, ytol)
	f_(x) = price_d-blsprice(S0, K, r, T, x, d, FlagIsCall)
	σ = FinancialToolbox.brentMethod(x->f_(hyper(x)).value, 0.001, 1.2, xtol, ytol)
	σ_der1 = FinancialToolbox.brentMethod(x->f_( hyper(σ,x,0.0,0.0)).epsilon1, -2.0, 1.2, 1e-15, 1e-15)
	σ_der2 = FinancialToolbox.brentMethod(x->f_( hyper(σ,σ_der1,x,0.0)).epsilon2, -2.0, 1.2, 1e-15, 1e-15)
	σ_der12 = FinancialToolbox.brentMethod(x->f_( hyper(σ,σ_der1,σ_der2,x)).epsilon12, -2.0, 1.2, 1e-15, 1e-15)
	return hyper(σ,σ_der1,σ_der2,σ_der12);
end
