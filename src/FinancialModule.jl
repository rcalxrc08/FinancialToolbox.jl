module FinancialModule

export normcdf;
if (VERSION.minor>=6)
	using SpecialFunctions.erf
end
function normcdf(x)
  return (1.0+erf(x/sqrt(2.0)))/2.0;
end

export normpdf;

function normpdf(x)
  return exp(-0.5*x.^2)/sqrt(2*pi);
end

export blsprice;
function blsprice{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
  #Black & Scholes Price for European Options
  blscheck(S0,K,r,T,sigma,d);
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  d2=d1-sigma*sqrt(T);
  Out=0.0;
  if (flag)
	Out=S0*exp(-d*T)*normcdf(d1)-K*exp(-r*T)*normcdf(d2);
  else
	Out=-S0*exp(-d*T)*normcdf(-d1)+K*exp(-r*T)*normcdf(-d2);
  end
return Out;
end

export blsdelta;
function blsdelta{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
  #Black & Scholes Delta for European Options
  blscheck(S0,K,r,T,sigma,d);
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  Out=0.0;
  if (flag)
	Out=exp(-d*T)*normcdf(d1);
  else
	Out=-exp(-d*T)*normcdf(-d1);
  end
return Out;
end

export blsgamma;
function blsgamma{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
  #Black & Scholes Gamma for European Options
  #For coherence i left the last boolean input.
  blscheck(S0,K,r,T,sigma,d);
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  Out=exp(-d*T)*normpdf(d1)/(S0*sigma*sqrt(T));
return Out;
end

export blsvega;
function blsvega{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
  #Black & Scholes Vega for European Options
  #For coherence i left the last boolean input.
  blscheck(S0,K,r,T,sigma,d);
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  Out=S0*exp(-d*T)*normpdf(d1)*sqrt(T);
return Out;
end

export blsrho;
function blsrho{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
  #Black & Scholes Rho for European Options
  blscheck(S0,K,r,T,sigma,d);
  d2=(log(S0/K)+(r-d-sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  if (flag)
	Out=K*exp(-r*T)*normcdf(d2)*T;
  else
    Out=-K*exp(-r*T)*normcdf(-d2)*T;
  end
return Out;
end

export blstheta;
function blstheta{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
  #Black & Scholes Theta for European Options
    blscheck(S0,K,r,T,sigma,d);
	sqrtT       = sqrt(T);
	sigma_sqrtT = sigma .* sqrtT;

	d1 = 1 ./ sigma_sqrtT .* (log(S0 ./ K) + (r - d + sigma.^2 / 2) .* T);
	
	disc  = exp(-d .* T);
	shift = -disc .* S0 .* normpdf(d1) .* sigma / 2 ./ sqrtT;
	t1    = r .* K   .* exp(-r .* T);
	t2    = d .* S0 .* disc;
	Out=0.0;
	if (flag)
		Out=shift - t1 .*      normcdf(d1 - sigma_sqrtT)  + t2 .*  normcdf(d1)     ;
	else
		Out=shift + t1 .* (1 - normcdf(d1 - sigma_sqrtT)) + t2 .* (normcdf(d1) - 1);
	end
	return Out;
end


export blscheck;
function blscheck{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0)
if isa(S0,Complex)
	if (S0.re< S0.re*0)
		error("Spot Price Cannot Be Negative")
	end
elseif isa(K,Complex)
	if (K.re< K.re*0)
		error("Strike Price Cannot Be Negative")
	end
elseif isa(T,Complex)
	if (T.re< T.re*0)
		error("Time to Maturity Cannot Be Negative")
	end
elseif isa(sigma,Complex)
	if (sigma.re< sigma.re*0)
		error("Volatility Cannot Be Negative")
	end
elseif (S0< A(0))
	error("Spot Price Cannot Be Negative")
elseif (K< B(0))
	error("Strike Price Cannot Be Negative")
elseif (T< D(0))
	error("Time to Maturity Cannot Be Negative")
elseif (sigma< E(0))
	error("Volatility Cannot Be Negative")
end
return;
end

#Brent Method: Scalar Equation Solver.
function brentMethod(f::Function, x0::Number, x1::Number,xtol::AbstractFloat=1e-14, ytol=2eps(Float64))
    EPS = eps(Float64)
	maxiter=80;
    y0 = f(x0)
    y1 = f(x1)
    if abs(y0) < abs(y1)
        # Swap lower and upper bounds.
        x0, x1 = x1, x0
        y0, y1 = y1, y0
    end
    x2 = x0
    y2 = y0
    x3 = x2
    bisection = true
    for _ in 1:maxiter
        # x-tolerance.
        if abs(x1-x0) < xtol
            return x1
        end

        # Use inverse quadratic interpolation if f(x0)!=f(x1)!=f(x2)
        # and linear interpolation (secant method) otherwise.
        if abs(y0-y2) > ytol && abs(y1-y2) > ytol
            x = x0*y1*y2/((y0-y1)*(y0-y2)) +
                x1*y0*y2/((y1-y0)*(y1-y2)) +
                x2*y0*y1/((y2-y0)*(y2-y1))
        else
            x = x1 - y1 * (x1-x0)/(y1-y0)
        end

        # Use bisection method if satisfies the conditions.
        delta = abs(2EPS*abs(x1))
        min1 = abs(x-x1)
        min2 = abs(x1-x2)
        min3 = abs(x2-x3)
        if (x < (3x0+x1)/4 && x > x1) ||
           (bisection && min1 >= min2/2) ||
           (!bisection && min1 >= min3/2) ||
           (bisection && min2 < delta) ||
           (!bisection && min3 < delta)
            x = (x0+x1)/2
            bisection = true
        else
            bisection = false
        end
        y = f(x)
        # y-tolerance.
        if abs(y) < ytol
            return x
        end
        x3 = x2
        x2 = x1
        if sign(y0) != sign(y)
            x1 = x
            y1 = y
        else
            x0 = x
            y0 = y
        end
        if abs(y0) < abs(y1)
            # Swap lower and upper bounds.
            x0, x1 = x1, x0
            y0, y1 = y1, y0
        end
    end
    error("Max iteration exceeded")
end

export blsimpv
using Optim
function blsimpv{A <: Real,B <: Real,C <: Real,D <: Real,E <: Real,F <: Real}(S0::A,K::B,r::C,T::D,Price::E,d::F=0.0,flag::Bool=true)
if (Price< E(0))
	error("Option Price Cannot Be Negative")
end
blscheck(S0,K,r,T,0.1,d);
f(x)=(blsprice(S0,K,r,T,x,d,flag)-Price);
ResultsOptimization=0;
try
	ResultsOptimization=brentMethod(f,0.001,1.2);
catch e
	error("The Inversion of Black Scholes Price Failed with the following error: $e")
end
Sigma=ResultsOptimization;
return Sigma;
end

end#End Module
