module FinancialModule

export normcdf;

function normcdf(x)
  return (1.0+erf(x/sqrt(2.0)))/2.0;
end

export normpdf;

function normpdf(x)
  return exp(-0.5*x.^2)/sqrt(2*pi);
end

export blsprice;
function blsprice(S0,K,r,T,sigma,d=0.0,flag=true)
  #Black & Scholes Price for European Options
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  d2=d1-sigma*sqrt(T);
  Out=0.0;
  if (flag==true)
	Out=S0*exp(-d*T)*normcdf(d1)-K*exp(-r*T)*normcdf(d2);
  else
	Out=-S0*exp(-d*T)*normcdf(-d1)+K*exp(-r*T)*normcdf(-d2);
  end
return Out;
end

export blsdelta;
function blsdelta(S0,K,r,T,sigma,d,flag=true)
  #Black & Scholes Delta for European Options
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  Out=0.0;
  if (flag==true)
	Out=exp(-d*T)*normcdf(d1);
  else
	Out=-exp(-d*T)*normcdf(-d1);
  end
return Out;
end

export blsgamma;
function blsgamma(S0,K,r,T,sigma,d,flag=true)
  #Black & Scholes Gamma for European Options
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  Out=exp(-d*T)*normpdf(d1)/(S0*sigma*sqrt(T));
return Out;
end

export blsvega;
function blsvega(S0,K,r,T,sigma,d,flag=true)
  #Black & Scholes Vega for European Options
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  Out=S0*exp(-d*T)*normpdf(d1)*sqrt(T);
return Out;
end

export blsrho;
function blsrho(S0,K,r,T,sigma,d,flag=true)
  #Black & Scholes Rho for European Options
  d2=(log(S0/K)+(r-d-sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  if (flag==true)
	Out=K*exp(-r*T)*normcdf(d2)*T;
  else
    Out=-K*exp(-r*T)*normcdf(-d2)*T;
  end
return Out;
end

export blstheta;
function blstheta(S0,K,r,T,sigma,d,flag=true)
  #Black & Scholes Theta for European Options
	sqrtT       = sqrt(T);
	sigma_sqrtT = sigma .* sqrtT;

	d1 = 1 ./ sigma_sqrtT .* (log(S0 ./ K) + (r - d + sigma.^2 / 2) .* T);
	d2 = d1 - sigma_sqrtT;

	phi1 = normcdf(d1);
	phi2 = normcdf(d2);

	disc  = exp(-d .* T);
	shift = -disc .* S0 .* normpdf(d1) .* sigma / 2 ./ sqrtT;
	t1    = r .* K   .* exp(-r .* T);
	t2    = d .* S0 .* disc;
	Out=0.0;
	if (flag==true)
		Out=shift - t1 .*      phi2  + t2 .*  phi1     ;
	else
		Out=shift + t1 .* (1 - phi2) + t2 .* (phi1 - 1);
	end
	return Out;
end

export blsimpv
using Optim
function blsimpv(S0,K,r,T,price,d,flag=true)

f(x)=(blsprice(S0,K,r,T,x,d,flag)-price).^2.0;
ResultsOptimization=optimize(f,1e-13,1.2);
Sigma=ResultsOptimization.minimum;
return Sigma;
end

end
