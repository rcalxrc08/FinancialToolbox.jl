function blsimpv(S0::num1,K::num2,r::num3,T::num4,Price::num5,d::num6=0.0,FlagIsCall::Bool=true,xtol::Real=1e-14,ytol::Real=1e-15) where {num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}
if (Price< num5(0))
	throw(ErrorException("Option Price Cannot Be Negative"));
end
blscheck(S0,K,r,T,0.1,d);
value__(x)=x.value;
value__(x::Real)=x;
f(x)=(blsprice(value(S0),value(K),value(r),value(T),x,value(d),FlagIsCall)-value(Price));
σ=brentMethod(f,0.001,1.2,xtol,ytol);

#der_=(blsvega(S0,K,r,T,σ,d)/blsprice(S0,K,r,T,σ,d))^-1
der_=blsprice(S0,K,r,T,σ,d,FlagIsCall)/blsvega(value(S0),value(K),value(r),value(T),σ,value(d),FlagIsCall)

return dual(σ,der_);

end

function blkimpv(S0::num1,K::num2,r::num3,T::num4,Price::num5,FlagIsCall::Bool=true,xtol::Real=1e-14,ytol::Real=1e-15) where {num1 ,num2 ,num3 ,num4 ,num5 ,num6 <: Number}

blscheck(S0,K,r,T,0.1,r);

return blsimpv(S0,K,r,T,Price,r,FlagIsCall);

end