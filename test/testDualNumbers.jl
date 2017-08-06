using Base.Test
using FinancialToolbox

print_with_color(:green,"Starting Dual Numbers Test\n")

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
using DualNumbers;
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
SpotDual=dual(spot,1.0);
rDual=dual(r,1.0);
TDual=dual(T,1.0);
SigmaDual=dual(sigma,1.0);

#Automatic Differentiation Test
#TEST
print_with_color(:yellow,"--- European Call Sensitivities: DualNumbers\n")
print_with_color(:blue,"-----Testing Delta\n");
@test(abs(FcallDual(SpotDual).epsilon-DeltaCall)<DerToll)
print_with_color(:blue,"-----Testing Rho\n");
@test(abs(GcallDual(rDual).epsilon-RhoCall)<DerToll)
print_with_color(:blue,"-----Testing Theta\n");
@test(abs(-HcallDual(TDual).epsilon-ThetaCall)<DerToll)
print_with_color(:blue,"-----Testing Lambda\n");
@test(abs(PcallDual(SpotDual).epsilon-LambdaCall)<DerToll)
print_with_color(:blue,"-----Testing Vanna\n");
@test(abs(VcallDual(SigmaDual).epsilon-VannaCall)<DerToll)
#TEST
print_with_color(:yellow,"--- European Put Sensitivities: DualNumbers\n")
print_with_color(:blue,"-----Testing Delta\n");
@test(abs(FputDual(SpotDual).epsilon-DeltaPut)<DerToll)
print_with_color(:blue,"-----Testing Rho\n");
@test(abs(GputDual(rDual).epsilon-RhoPut)<DerToll)
print_with_color(:blue,"-----Testing Theta\n");
@test(abs(-HputDual(TDual).epsilon-ThetaPut)<DerToll)
print_with_color(:blue,"-----Testing Lambda\n");
@test(abs(PputDual(SpotDual).epsilon-LambdaPut)<DerToll)
print_with_color(:blue,"-----Testing Vanna\n");
@test(abs(VPutDual(SigmaDual).epsilon-VannaPut)<DerToll)

print_with_color(:blue,"-----Testing Vega\n");
@test(abs(LcallDual(SigmaDual).epsilon-Vega)<DerToll)
print_with_color(:green,"Dual Numbers Test Passed\n")
println("")

#TEST OF INPUT VALIDATION
print_with_color(:magenta,"Starting Input Validation Test Dual\n")
print_with_color(:cyan,"----Testing Negative  Spot Price \n")
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

print_with_color(:cyan,"----Testing Negative  Strike Price \n")
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

print_with_color(:cyan,"----Testing Negative  Time to Maturity \n")
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

print_with_color(:cyan,"----Testing Negative  Volatility \n")
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

print_with_color(:magenta,"Dual Input Validation Test Passed\n")