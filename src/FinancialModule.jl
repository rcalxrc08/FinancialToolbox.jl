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

export blsimpv
using Optim
function blsimpv{A <: Real,B <: Real,C <: Real,D <: Real,E <: Real,F <: Real}(S0::A,K::B,r::C,T::D,Price::E,d::F=0.0,flag::Bool=true)
if (Price< E(0))
	error("Option Price Cannot Be Negative")
end
blscheck(S0,K,r,T,0.1,d);
f(x)=(blsprice(S0,K,r,T,x,d,flag)-Price).^2.0;
ResultsOptimization=0;
try
	ResultsOptimization=optimize(f,0.001,1.2,Optim.Brent(),abs_tol=1e-16,rel_tol=1e-16);
catch 
	error("The One-Dimensional Solver was not able to invert the BS Formula"+catch_backtrace())
end
Sigma=ResultsOptimization.minimizer;
return Sigma;
end

end
