if (VERSION.major==0&&VERSION.minor>6)
	using Test
	using ForwardDiff: Dual;
else
	using Base.Test
	using ForwardDiff.Dual;
end
using FinancialToolbox
printstyled("Starting Forward Diff Dual Numbers Test\n",color=:green)

#Test Parameters
testToll=1e-14;
spot=10;K=10;r=0.02;T=2.0;sigma=0.2;d=0.01;

#EuropeanCall Option
PriceCall=blsprice(spot,K,r,T,sigma,d);
DeltaCall=blsdelta(spot,K,r,T,sigma,d);
ThetaCall=blstheta(spot,K,r,T,sigma,d);
RhoCall=blsrho(spot,K,r,T,sigma,d);
LambdaCall=blslambda(spot,K,r,T,sigma,d);
VannaCall=blsvanna(spot,K,r,T,sigma,d);

#EuropeanPut Option
PricePut=blsprice(spot,K,r,T,sigma,d,false);
DeltaPut=blsdelta(spot,K,r,T,sigma,d,false);
ThetaPut=blstheta(spot,K,r,T,sigma,d,false);
RhoPut=blsrho(spot,K,r,T,sigma,d,false);
LambdaPut=blslambda(spot,K,r,T,sigma,d,false);
VannaPut=blsvanna(spot,K,r,T,sigma,d,false);

#Equals for both Options
Gamma=blsgamma(spot,K,r,T,sigma,d);
Vega=blsvega(spot,K,r,T,sigma,d);

########DUAL NUMBERS
DerToll=1e-13;
#Function definition
#Call
FcallDual(spot)=blsprice(spot,K,r,T,sigma,d);
GcallDual(r)=blsprice(spot,K,r,T,sigma,d);
HcallDual(T)=blsprice(spot,K,r,T,sigma,d);
LcallDual(sigma)=blsprice(spot,K,r,T,sigma,d);
PcallDual(spot)=blsprice(spot,K,r,T,sigma,d)*spot.value/blsprice(spot.value,K,r,T,sigma,d);
VcallDual(sigma)=blsdelta(spot,K,r,T,sigma,d);
#Put
FputDual(spot)=blsprice(spot,K,r,T,sigma,d,false);
GputDual(r)=blsprice(spot,K,r,T,sigma,d,false);
HputDual(T)=blsprice(spot,K,r,T,sigma,d,false);
PputDual(spot)=blsprice(spot,K,r,T,sigma,d,false)*spot.value/blsprice(spot.value,K,r,T,sigma,d,false);
VPutDual(sigma)=blsdelta(spot,K,r,T,sigma,d,false);
#Input
SpotDual=Dual(spot,1.0);
rDual=Dual(r,1.0);
TDual=Dual(T,1.0);
SigmaDual=Dual(sigma,1.0);

#Automatic Differentiation Test
#TEST
printstyled("--- European Call Sensitivities: DualNumbers\n",color=:yellow)
printstyled("-----Testing Delta\n",color=:blue);
@test(abs(FcallDual(SpotDual).partials[1]-DeltaCall)<DerToll)
printstyled("-----Testing Rho\n",color=:blue);
@test(abs(GcallDual(rDual).partials[1]-RhoCall)<DerToll)
printstyled("-----Testing Theta\n",color=:blue);
@test(abs(-HcallDual(TDual).partials[1]-ThetaCall)<DerToll)
printstyled("-----Testing Lambda\n",color=:blue);
@test(abs(PcallDual(SpotDual).partials[1]-LambdaCall)<DerToll)
printstyled("-----Testing Vanna\n",color=:blue);
@test(abs(VcallDual(SigmaDual).partials[1]-VannaCall)<DerToll)
#TEST
printstyled("--- European Put Sensitivities: DualNumbers\n",color=:yellow)
printstyled("-----Testing Delta\n",color=:blue);
@test(abs(FputDual(SpotDual).partials[1]-DeltaPut)<DerToll)
printstyled("-----Testing Rho\n",color=:blue);
@test(abs(GputDual(rDual).partials[1]-RhoPut)<DerToll)
printstyled("-----Testing Theta\n",color=:blue);
@test(abs(-HputDual(TDual).partials[1]-ThetaPut)<DerToll)
printstyled("-----Testing Lambda\n",color=:blue);
@test(abs(PputDual(SpotDual).partials[1]-LambdaPut)<DerToll)
printstyled("-----Testing Vanna\n",color=:blue);
@test(abs(VPutDual(SigmaDual).partials[1]-VannaPut)<DerToll)

printstyled("-----Testing Vega\n",color=:blue);
@test(abs(LcallDual(SigmaDual).partials[1]-Vega)<DerToll)
printstyled("Dual Numbers Test Passed\n",color=:green)
println("")

#TEST OF INPUT VALIDATION
printstyled("Starting Input Validation Test Dual\n",color=:magenta)
printstyled("----Testing Negative  Spot Price \n",color=:cyan)
@test_throws(ErrorException, blsprice(-SpotDual,K,r,T,sigma,d))
@test_throws(ErrorException, blkprice(-SpotDual,K,r,T,sigma))
@test_throws(ErrorException, blsdelta(-SpotDual,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-SpotDual,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-SpotDual,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-SpotDual,K,r,T,sigma,d))
@test_throws(ErrorException, blspsi(-SpotDual,K,r,T,sigma,d))
@test_throws(ErrorException, blslambda(-SpotDual,K,r,T,sigma,d))
@test_throws(ErrorException, blsvanna(-SpotDual,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-SpotDual,K,r,T,sigma,d))

printstyled("----Testing Negative  Strike Price \n",color=:cyan)
KK=Dual(K,0);
@test_throws(ErrorException, blsprice(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blkprice(spot,-KK,r,T,sigma))
@test_throws(ErrorException, blsdelta(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blspsi(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blslambda(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blsvanna(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-KK,r,T,sigma,d))

printstyled("----Testing Negative  Time to Maturity \n",color=:cyan)
@test_throws(ErrorException, blsprice(spot,K,r,-TDual,sigma,d))
@test_throws(ErrorException, blkprice(spot,K,r,-TDual,sigma))
@test_throws(ErrorException, blsdelta(spot,K,r,-TDual,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-TDual,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-TDual,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-TDual,sigma,d))
@test_throws(ErrorException, blspsi(spot,K,r,-TDual,sigma,d))
@test_throws(ErrorException, blslambda(spot,K,r,-TDual,sigma,d))
@test_throws(ErrorException, blsvanna(spot,K,r,-TDual,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-TDual,sigma,d))

printstyled("----Testing Negative  Volatility \n",color=:cyan)
@test_throws(ErrorException, blsprice(spot,K,r,T,-SigmaDual,d))
@test_throws(ErrorException, blkprice(spot,K,r,T,-SigmaDual))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-SigmaDual,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-SigmaDual,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-SigmaDual,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-SigmaDual,d))
@test_throws(ErrorException, blspsi(spot,K,r,T,-SigmaDual,d))
@test_throws(ErrorException, blslambda(spot,K,r,T,-SigmaDual,d))
@test_throws(ErrorException, blsvanna(spot,K,r,T,-SigmaDual,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-SigmaDual,d))

printstyled("Dual Input Validation Test Passed\n",color=:magenta)