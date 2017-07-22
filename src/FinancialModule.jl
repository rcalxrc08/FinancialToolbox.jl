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
"""
Black & Scholes Price for European Options

    Price=blsprice(S0,K,r,T,sigma,d=0.0,FlagIsCall=true)
	
Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	sigma      = Implied Volatility.
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Price      = price of the European Option.

# Example
```julia-repl
julia> blsprice(10.0,10.0,0.01,2.0,0.2,0.01)
1.1023600107733191
```
"""
function blsprice{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
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
"""
Black & Scholes Delta for European Options

    Delta=blsdelta(S0,K,r,T,sigma,d=0.0,FlagIsCall=true)
	
Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	sigma      = Implied Volatility.
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Delta= delta of the European Option.

# Example
```julia-repl
julia> blsdelta(10.0,10.0,0.01,2.0,0.2,0.01)
0.5452173371920436
```
"""
function blsdelta{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
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
"""
Black & Scholes Gamma for European Options

    Gamma=blsgamma(S0,K,r,T,sigma,d=0.0,FlagIsCall=true)
	
Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	sigma      = Implied Volatility.
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Gamma      = gamma of the European Option.

# Example
```julia-repl
julia> blsgamma(10.0,10.0,0.01,2.0,0.2,0.01)
0.13687881535712826
```
"""
function blsgamma{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
  #For coherence i left the last boolean input.
  blscheck(S0,K,r,T,sigma,d);
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  Out=exp(-d*T)*normpdf(d1)/(S0*sigma*sqrt(T));
return Out;
end

export blsvega;
"""
Black & Scholes Vega for European Options

    Vega=blsvega(S0,K,r,T,sigma,d=0.0,FlagIsCall=true)
	
Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	sigma      = Implied Volatility.
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Vega       = vega of the European Option.

# Example
```julia-repl
julia> blsvega(10.0,10.0,0.01,2.0,0.2,0.01)
5.475152614285131
```
"""
function blsvega{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
  #For coherence i left the last boolean input.
  blscheck(S0,K,r,T,sigma,d);
  d1=(log(S0/K)+(r-d+sigma*sigma*0.5)*T)/(sigma*sqrt(T));
  Out=S0*exp(-d*T)*normpdf(d1)*sqrt(T);
return Out;
end

export blsrho;
"""
Black & Scholes Rho for European Options

    Rho=blsrho(S0,K,r,T,sigma,d=0.0,FlagIsCall=true)
	
Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	sigma      = Implied Volatility.
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Rho        = rho of the European Option.

# Example
```julia-repl
julia> blsrho(10.0,10.0,0.01,2.0,0.2,0.01)
8.699626722294234
```
"""
function blsrho{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
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
"""
Black & Scholes Theta for European Options

    Theta=blstheta(S0,K,r,T,sigma,d=0.0,FlagIsCall=true)
	
Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	sigma      = Implied Volatility.
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Theta      = theta of the European Option.

# Example
```julia-repl
julia> blstheta(10.0,10.0,0.01,2.0,0.2,0.01)
-0.26273403060652334
```
"""
function blstheta{A <: Number,B <: Number,C <: Number,D <: Number,E <: Number,F <: Number}(S0::A,K::B,r::C,T::D,sigma::E,d::F=0.0,flag::Bool=true)
    blscheck(S0,K,r,T,sigma,d);
	sqrtT       = sqrt(T);
	sigma_sqrtT = sigma .* sqrtT;

	d1 = (log(S0 ./ K) + (r - d + sigma.^2 / 2) .* T)./ sigma_sqrtT;

	shift = -exp(-d .* T) .* S0 .* normpdf(d1) .* sigma / 2 ./ sqrtT;
	t1    = r .* K   .* exp(-r .* T);
	t2    = d .* S0 .* exp(-d .* T);
	Out=0.0;
	if (flag)
		Out=shift - t1 .*      normcdf(d1 - sigma_sqrtT)  + t2 .*  normcdf(d1)     ;
	else
		Out=shift + t1 .* (1 - normcdf(d1 - sigma_sqrtT)) + t2 .* (normcdf(d1) - 1);
	end
	return Out;
end


"Check input for Black Scholes Formula"
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

"Brent Method: Scalar Equation Solver"
function brentMethod(f::Function, x0::Number, x1::Number,xtol::AbstractFloat=1e-14, ytol::AbstractFloat=1e-15)
    if xtol<0.0
      error("x tollerance cannot be negative")
    end
	if ytol<0.0
      error("y tollerance cannot be negative")
    end
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
    error("Max iteration exceeded, possible wrong result")
end

export blsimpv
"""
Black & Scholes Implied Volatility for European Options

    Volatility=blsimpv(S0,K,r,T,Price,d=0.0,FlagIsCall=true,xtol=1e-14,ytol=1e-15) 
	
Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	Price      = Price of the Option.
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Volatility = implied volatility of the European Option.

# Example
```julia-repl
julia> blsimpv(10.0,10.0,0.01,2.0,2.0)
0.3433730534290586
```
"""
function blsimpv{A <: Real,B <: Real,C <: Real,D <: Real,E <: Real,F <: Real}(S0::A,K::B,r::C,T::D,Price::E,d::F=0.0,flag::Bool=true,xtol::Real=1e-14,ytol::Real=1e-15)
if (Price< E(0))
	error("Option Price Cannot Be Negative")
end
blscheck(S0,K,r,T,0.1,d);
f(x)=(blsprice(S0,K,r,T,x,d,flag)-Price);
ResultsOptimization=0;
try
	ResultsOptimization=brentMethod(f,0.001,1.2,xtol,ytol);
catch e
	error("The Inversion of Black Scholes Price Failed with the following error: $e")
end
Sigma=ResultsOptimization;
return Sigma;
end

end#End Module
