function normcdf{number <: Number}(x::number)
  return (1.0+erf(x/sqrt(2.0)))/2.0;
end

function normpdf{number <: Number}(x::number)
  return exp(-0.5*x.^2)/sqrt(2*pi);
end


"""
Black & Scholes Price for European Options

    Price=blsprice(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Price      = price of the European Option.

# Example
```julia-repl
julia> blsprice(10.0,10.0,0.01,2.0,0.2,0.01)
1.1023600107733191
```
"""
function blsprice{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
  blscheck(S0,K,r,T,σ,d);
  d1=(log(S0/K)+(r-d+σ*σ*0.5)*T)/(σ*sqrt(T));
  d2=d1-σ*sqrt(T);
  Out=0.0;
  if FlagIsCall
	Out=S0*exp(-d*T)*normcdf(d1)-K*exp(-r*T)*normcdf(d2);
  else
	Out=-S0*exp(-d*T)*normcdf(-d1)+K*exp(-r*T)*normcdf(-d2);
  end
return Out;
end


"""
Black Price for European Options

    Price=blkprice(F0,K,r,T,σ,FlagIsCall=true)

Where:\n
	F0         = Value of the Forward.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility.
	FlagIsCall = true for Call Options, false for Put Options.

	Price      = price of the European Option.

# Example
```julia-repl
julia> blkprice(10.0,10.0,0.01,2.0,0.2)
1.1023600107733191
```
"""
function blkprice{num1 ,num2 ,num3 ,num4 ,num5 <: Number}(F0::num1,K::num2,r::num3,T::num4,σ::num5,FlagIsCall::Bool=true)
  blscheck(F0,K,r,T,σ);
  Out=blsprice(F0,K,r,T,σ,r,FlagIsCall);
return Out;
end


"""
Black & Scholes Delta for European Options

    Delta=blsdelta(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Delta= delta of the European Option.

# Example
```julia-repl
julia> blsdelta(10.0,10.0,0.01,2.0,0.2,0.01)
0.5452173371920436
```
"""
function blsdelta{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
  blscheck(S0,K,r,T,σ,d);
  d1=(log(S0/K)+(r-d+σ*σ*0.5)*T)/(σ*sqrt(T));
  Out=0.0;
  if FlagIsCall
	Out=exp(-d*T)*normcdf(d1);
  else
	Out=-exp(-d*T)*normcdf(-d1);
  end
return Out;
end


"""
Black & Scholes Gamma for European Options

    Gamma=blsgamma(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Gamma      = gamma of the European Option.

# Example
```julia-repl
julia> blsgamma(10.0,10.0,0.01,2.0,0.2,0.01)
0.13687881535712826
```
"""
function blsgamma{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
  #For coherence i left the last boolean input.
  blscheck(S0,K,r,T,σ,d);
  d1=(log(S0/K)+(r-d+σ*σ*0.5)*T)/(σ*sqrt(T));
  Out=exp(-d*T)*normpdf(d1)/(S0*σ*sqrt(T));
return Out;
end


"""
Black & Scholes Vega for European Options

    Vega=blsvega(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Vega       = vega of the European Option.

# Example
```julia-repl
julia> blsvega(10.0,10.0,0.01,2.0,0.2,0.01)
5.475152614285131
```
"""
function blsvega{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
  #For coherence i left the last boolean input.
  blscheck(S0,K,r,T,σ,d);
  d1=(log(S0/K)+(r-d+σ*σ*0.5)*T)/(σ*sqrt(T));
  Out=S0*exp(-d*T)*normpdf(d1)*sqrt(T);
return Out;
end


"""
Black & Scholes Rho for European Options

    Rho=blsrho(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Rho        = rho of the European Option.

# Example
```julia-repl
julia> blsrho(10.0,10.0,0.01,2.0,0.2,0.01)
8.699626722294234
```
"""
function blsrho{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
  blscheck(S0,K,r,T,σ,d);
  d2=(log(S0/K)+(r-d-σ*σ*0.5)*T)/(σ*sqrt(T));
  if FlagIsCall
	Out=K*exp(-r*T)*normcdf(d2)*T;
  else
    Out=-K*exp(-r*T)*normcdf(-d2)*T;
  end
return Out;
end


"""
Black & Scholes Theta for European Options

    Theta=blstheta(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Theta      = theta of the European Option.

# Example
```julia-repl
julia> blstheta(10.0,10.0,0.01,2.0,0.2,0.01)
-0.26273403060652334
```
"""
function blstheta{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
    blscheck(S0,K,r,T,σ,d);
	sqrtT       = sqrt(T);
	σ_sqrtT = σ .* sqrtT;

	d1 = (log(S0 ./ K) + (r - d + σ.^2 / 2) .* T)./ σ_sqrtT;

	shift = -exp(-d .* T) .* S0 .* normpdf(d1) .* σ / 2 ./ sqrtT;
	t1    = r .* K   .* exp(-r .* T);
	t2    = d .* S0 .* exp(-d .* T);
	Out=0.0;
	if FlagIsCall
		Out=shift - t1 .*      normcdf(d1 - σ_sqrtT)  + t2 .*  normcdf(d1)     ;
	else
		Out=shift + t1 .* (1 - normcdf(d1 - σ_sqrtT)) + t2 .* (normcdf(d1) - 1);
	end
	return Out;
end


"""
Black & Scholes Lambda for European Options

    Lambda=blslambda(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Lambda        = lambda of the European Option.

# Example
```julia-repl
julia> blslambda(10.0,10.0,0.01,2.0,0.2,0.01)
4.945909973725978
```
"""
function blslambda{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
  blscheck(S0,K,r,T,σ,d);
  Price=blsprice(S0,K,r,T,σ,d,FlagIsCall);
  tmpOut=blsdelta(S0,K,r,T,σ,d,FlagIsCall);
  Out=tmpOut*S0/Price;
return Out;
end


"Check input for Black Scholes Formula"
function blscheck{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0)
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
elseif isa(σ,Complex)
	if (σ.re< σ.re*0)
		error("Volatility Cannot Be Negative")
	end
elseif (S0< num1(0))
	error("Spot Price Cannot Be Negative")
elseif (K< num2(0))
	error("Strike Price Cannot Be Negative")
elseif (T< num4(0))
	error("Time to Maturity Cannot Be Negative")
elseif (σ< num5(0))
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
    EPS = eps(Number)
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
function blsimpv{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Real}(S0::num1,K::num2,r::num3,T::num4,Price::num5,d::num6=0.0,FlagIsCall::Bool=true,xtol::Real=1e-14,ytol::Real=1e-15)
if (Price< num5(0))
	error("Option Price Cannot Be Negative")
end
blscheck(S0,K,r,T,0.1,d);
f(x)=(blsprice(S0,K,r,T,x,d,FlagIsCall)-Price);
ResultsOptimization=0;
try
	ResultsOptimization=brentMethod(f,0.001,1.2,xtol,ytol);
catch e
	error("The Inversion of Black Scholes Price Failed with the following error: $e")
end
σ=ResultsOptimization;
return σ;
end

export blkimpv
"""
Black Implied Volatility for European Options

    σ=blkimpv(S0,K,r,T,Price,d=0.0,FlagIsCall=true,xtol=1e-14,ytol=1e-15)

Where:\n
	S0         = Value of the Forward.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	Price      = Price of the Option.
	FlagIsCall = true for Call Options, false for Put Options.

	σ = implied volatility of the European Option.

# Example
```julia-repl
julia> blkimpv(10.0,10.0,0.01,2.0,2.0)
0.36568658096623635
```
"""
function blkimpv{num1 ,num2 ,num3 ,num4 ,num5 <: Real}(S0::num1,K::num2,r::num3,T::num4,Price::num5,FlagIsCall::Bool=true,xtol::Real=1e-14,ytol::Real=1e-15)
σ=blsimpv(S0,K,r,T,Price,r,FlagIsCall,xtol,ytol)
return σ;
end

##	ADDITIONAL Function

"""
Black & Scholes Psi for European Options

    Psi=blspsi(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Psi        = psi of the European Option.

# Example
```julia-repl
julia> blspsi(10.0,10.0,0.01,2.0,0.2,0.01)
-10.904346743840872
```
"""
function blspsi{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
  blscheck(S0,K,r,T,σ,d);
  d1=(log(S0/K)+(r-d+σ*σ*0.5)*T)/(σ*sqrt(T));
  if FlagIsCall
	Out=-S0*exp(-d*T)*normcdf(d1)*T;
  else
    Out=S0*exp(-d*T)*normcdf(-d1)*T;
  end
return Out;
end


"""
Black & Scholes Vanna for European Options

    Vanna=blsvanna(S0,K,r,T,σ,d=0.0,FlagIsCall=true)

Where:\n
	S0         = Value of the Underlying.
	K          = Strike Price of the Option.
	r          = Zero Rate.
	T          = Time to Maturity of the Option.
	σ          = Implied Volatility
	d          = Implied Dividend of the Underlying.
	FlagIsCall = true for Call Options, false for Put Options.

	Vanna        = vanna of the European Option.

# Example
```julia-repl
julia> blsvanna(10.0,10.0,0.01,2.0,0.2,0.01)
0.2737576307142566
```
"""
function blsvanna{num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}(S0::num1,K::num2,r::num3,T::num4,σ::num5,d::num6=0.0,FlagIsCall::Bool=true)
  blscheck(S0,K,r,T,σ,d);
  d1=(log(S0/K)+(r-d+σ*σ*0.5)*T)/(σ*sqrt(T));
  d2=d1-σ*sqrt(T);
  Out=-exp(-d*T)*normpdf(d1)*d2/σ;
return Out;
end
