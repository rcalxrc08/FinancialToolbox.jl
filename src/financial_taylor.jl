using .TaylorSeries
function FinancialToolbox.normcdf(x::Taylor1)
    out = zero(x)
    @inbounds @views out[0] = FinancialToolbox.normcdf(x[0])
    lout = get_order(out) - 1
    if (get_order(out) == 0)
        return out
    end
    ders_t = FinancialToolbox.normpdf(x)
    x_der = derivative(x, 1)
    #Faa di Bruno
    prev_der = ders_t * x_der
    @views out[1] = prev_der[0]
    for i = 1:lout
        prev_der = derivative(prev_der, 1)
        if (i < 20)
            @views out[i+1] = prev_der[0] / factorial(i + 1)
        else
            @views out[i+1] = Float64(prev_der[0] / factorial(big(i + 1)))
        end
    end
    return out
end
# TODO: move to proper implementation: https://github.com/JuliaDiff/TaylorSeries.jl/issues/285
function FinancialToolbox.normcdf(x::TaylorN)
    Nmax = 20000
    xmin = -5.0
    x_ = range(xmin, length = Nmax, stop = x)
    dx = (x - xmin) / (Nmax - 1)
    return sum(FinancialToolbox.normpdf.(x_)) * dx
end

!hasmethod(isless, (Taylor1, Taylor1)) ? (Base.isless(x::Taylor1, y::Taylor1) = x[0] < y[0]) : nothing
!hasmethod(isless, (TaylorN, TaylorN)) ? (Base.isless(x::TaylorN, y::TaylorN) = x[0][1] < y[0][1]) : nothing

value__d(x::Taylor1) = x[0]
value__d(x::TaylorN) = x[0][1]
value__d(x) = x

function blsimpv_impl(zero_typed::Taylor1, S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
    S0_r=value__d(S0)
	K_r=value__d(K)
	r_r=value__d(r)
	T_r=value__d(T)
	p_r=value__d(price_d)
	d_r=value__d(d)
	sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r, FlagIsCall, xtol, ytol)
	der_ = (price_d-blsprice(S0, K, r, T, sigma, d, FlagIsCall)) / blsvega(S0_r, K_r, r_r, T_r, sigma, d_r)
	out = sigma+der_
	return out;
end

function blsimpv_impl(zero_typed::TaylorN, S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
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