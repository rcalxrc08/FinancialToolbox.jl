using .ForwardDiff
Dual_=ForwardDiff.Dual

function blkimpv_fwd(num1,num2,num3,num4,num5)
	@eval function blkimpv(S0::$num1,K::$num2,r::$num3,T::$num4,Price::$num5,FlagIsCall::Bool=true,xtol::Real=1e-14,ytol::Real=1e-15)

		blscheck(S0,K,r,T,0.1,r);

		return blsimpv(S0,K,r,T,Price,r,FlagIsCall);

	end
end


type_blkimpv_dual_fwd_1=[Dual_,Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_}]
type_blkimpv_dual_fwd_2=[Real,Dual_,Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_}]
type_blkimpv_dual_fwd_3=[Real,Real,Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_}]
blkimpv_fwd(type_blkimpv_dual_fwd_1[1],type_blkimpv_dual_fwd_1[2],type_blkimpv_dual_fwd_1[3],type_blkimpv_dual_fwd_1[4],type_blkimpv_dual_fwd_1[5])
blkimpv_fwd(type_blkimpv_dual_fwd_2[1],type_blkimpv_dual_fwd_2[2],type_blkimpv_dual_fwd_2[3],type_blkimpv_dual_fwd_2[4],type_blkimpv_dual_fwd_2[5])
blkimpv_fwd(type_blkimpv_dual_fwd_3[1],type_blkimpv_dual_fwd_3[2],type_blkimpv_dual_fwd_3[3],type_blkimpv_dual_fwd_3[4],type_blkimpv_dual_fwd_3[5])

function blsimpv_fwd(num1,num2,num3,num4,num5,num6)
	@eval function blsimpv(S0::$num1,K::$num2,r::$num3,T::$num4,Price::$num5,d::$num6=0.0,FlagIsCall::Bool=true,xtol::Real=1e-14,ytol::Real=1e-15)
	if (Price< $num5(0))
		throw(ErrorException("Option Price Cannot Be Negative"));
	end
	FinancialToolbox.blscheck(S0,K,r,T,0.1,d);
	value__(x)=x.value;
	value__(x::Real)=x;
	f(x)=(blsprice(value__(S0),value__(K),value__(r),value__(T),x,value__(d),FlagIsCall)-value__(Price));
	σ=FinancialToolbox.brentMethod(f,0.001,1.2,xtol,ytol);
	out=ForwardDiff.Dual(0.0,0.0);

	if(!($num5<:ForwardDiff.Dual))
		der_=-(blsprice(S0,K,r,T,σ,d,FlagIsCall)/blsvega(value__(S0),value__(K),value__(r),value__(T),σ,value__(d),FlagIsCall)).partials
		out=ForwardDiff.Dual(σ,der_);
	else
		der_=1/blsvega(value__(S0),value__(K),value__(r),value__(T),σ,value__(d),FlagIsCall)
		out=ForwardDiff.Dual(σ,der_);
	end

	return out;

	end
end

type_blsimpv_dual_fwd_1=[Dual_,Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_}]
type_blsimpv_dual_fwd_2=[Real,Dual_,Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_}]
type_blsimpv_dual_fwd_3=[Real,Real,Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_},Union{Real,Dual_}]
blsimpv_fwd(type_blsimpv_dual_fwd_1[1],type_blsimpv_dual_fwd_1[2],type_blsimpv_dual_fwd_1[3],type_blsimpv_dual_fwd_1[4],type_blsimpv_dual_fwd_1[5],type_blsimpv_dual_fwd_1[6])
blsimpv_fwd(type_blsimpv_dual_fwd_2[1],type_blsimpv_dual_fwd_2[2],type_blsimpv_dual_fwd_2[3],type_blsimpv_dual_fwd_2[4],type_blsimpv_dual_fwd_2[5],type_blsimpv_dual_fwd_2[6])
blsimpv_fwd(type_blsimpv_dual_fwd_3[1],type_blsimpv_dual_fwd_3[2],type_blsimpv_dual_fwd_3[3],type_blsimpv_dual_fwd_3[4],type_blsimpv_dual_fwd_3[5],type_blsimpv_dual_fwd_3[6])
