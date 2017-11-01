using Base.Test
using FinancialToolbox

print_with_color(:green,"Starting Hyper Dual Numbers Test\n")

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

########HYPER DUAL NUMBERS
using HyperDualNumbers;
DerToll=1e-13;
di=1e-15;
#Function definition
SpotHyper=hyper(spot,1.0,1.0,0.0);
rHyper=hyper(r,1.0,1.0,0.0);
THyper=hyper(T,1.0,1.0,0.0);
SigmaHyper=hyper(sigma,1.0,1.0,0.0);
KHyper=hyper(K,1.0,1.0,0.0);


#Function definition
#Call
F(spot)=blsprice(spot,K,r,T,sigma,d);
FF(spot)=blsdelta(spot,K,r,T,sigma,d);
G(r)=blsprice(spot,K,r,T,sigma,d);
H(T)=blsprice(spot,K,r,T,sigma,d);
L(sigma)=blsprice(spot,K,r,T,sigma,d);
P(spot)=blsprice(spot,K,r,T,sigma,d)*spot.f0/blsprice(spot.f0,K,r,T,sigma,d);
V(sigma)=blsdelta(spot,K,r,T,sigma,d);
VV(spot,sigma)=blsprice(spot,K,r,T,sigma,d);
#Put
F1(spot)=blsprice(spot,K,r,T,sigma,d,false);
FF1(spot)=blsdelta(spot,K,r,T,sigma,d,false);
G1(r)=blsprice(spot,K,r,T,sigma,d,false);
H1(T)=blsprice(spot,K,r,T,sigma,d,false);
P1(spot)=blsprice(spot,K,r,T,sigma,d,false)*spot.f0/blsprice(spot.f0,K,r,T,sigma,d,false);
V1(sigma)=blsdelta(spot,K,r,T,sigma,d,false);
V11(spot,sigma)=blsprice(spot,K,r,T,sigma,d,false);

#TEST
print_with_color(:yellow,"--- European Call Sensitivities: HyperDualNumbers\n")
print_with_color(:blue,"-----Testing Delta\n");
@test(abs(F(SpotHyper).f1-DeltaCall)<DerToll)
print_with_color(:blue,"-----Testing Gamma\n");
@test(abs(FF1(SpotHyper).f1-Gamma)<DerToll)
print_with_color(:blue,"-----Testing Gamma  2\n");
@test(abs(F(SpotHyper).f12-Gamma)<DerToll)
print_with_color(:blue,"-----Testing Rho\n");
@test(abs(G(rHyper).f1-RhoCall)<DerToll)
print_with_color(:blue,"-----Testing Theta\n");
@test(abs(-H(THyper).f1-ThetaCall)<DerToll)
print_with_color(:blue,"-----Testing Lambda\n");
@test(abs(P(SpotHyper).f1-LambdaCall)<DerToll)
print_with_color(:blue,"-----Testing Vanna\n");
@test(abs(V(SigmaHyper).f1-VannaCall)<DerToll)
print_with_color(:blue,"-----Testing Vanna  2\n");
@test(abs(VV(hyper(spot,1,0,0),hyper(sigma,0,1,0)).f12-VannaCall)<DerToll)

## Complex Test with Complex Step Approximation for European Put
#TEST
print_with_color(:yellow,"--- European Put Sensitivities: HyperDualNumbers\n")
print_with_color(:blue,"-----Testing Delta\n");
@test(abs(F1(SpotHyper).f1-DeltaPut)<DerToll)
print_with_color(:blue,"-----Testing Rho\n");
@test(abs(G1(rHyper).f1-RhoPut)<DerToll)
print_with_color(:blue,"-----Testing Theta\n");
@test(abs(-H1(THyper).f1-ThetaPut)<DerToll)
print_with_color(:blue,"-----Testing Lambda\n");
@test(abs(P1(SpotHyper).f1-LambdaPut)<DerToll)
print_with_color(:blue,"-----Testing Vanna\n");
@test(abs(V1(SigmaHyper).f1-VannaPut)<DerToll)
print_with_color(:blue,"-----Testing Vanna  2\n");
@test(abs(V11(hyper(spot,1,0,0),hyper(sigma,0,1,0)).f12-VannaPut)<DerToll)
print_with_color(:blue,"-----Testing Vega\n");
@test(abs(L(SigmaHyper).f1-Vega)<DerToll)
print_with_color(:green,"Hyper Dual Numbers Test Passed\n\n")



#TEST OF INPUT VALIDATION
print_with_color(:magenta,"Starting Input Validation Test Hyper Dual Numbers\n")
print_with_color(:cyan,"----Testing Negative  Spot Price \n")
@test_throws(ErrorException, blsprice(-SpotHyper,K,r,T,sigma,d))
@test_throws(ErrorException, blkprice(-SpotHyper,K,r,T,sigma))
@test_throws(ErrorException, blsdelta(-SpotHyper,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-SpotHyper,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-SpotHyper,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-SpotHyper,K,r,T,sigma,d))
@test_throws(ErrorException, blspsi(-SpotHyper,K,r,T,sigma,d))
@test_throws(ErrorException, blslambda(-SpotHyper,K,r,T,sigma,d))
@test_throws(ErrorException, blsvanna(-SpotHyper,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-SpotHyper,K,r,T,sigma,d))

print_with_color(:cyan,"----Testing Negative  Strike Price \n")
@test_throws(ErrorException, blsprice(spot,-KHyper,r,T,sigma,d))
@test_throws(ErrorException, blkprice(spot,-KHyper,r,T,sigma))
@test_throws(ErrorException, blsdelta(spot,-KHyper,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-KHyper,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-KHyper,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-KHyper,r,T,sigma,d))
@test_throws(ErrorException, blspsi(spot,-KHyper,r,T,sigma,d))
@test_throws(ErrorException, blslambda(spot,-KHyper,r,T,sigma,d))
@test_throws(ErrorException, blsvanna(spot,-KHyper,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-KHyper,r,T,sigma,d))

print_with_color(:cyan,"----Testing Negative  Time to Maturity \n")
@test_throws(ErrorException, blsprice(spot,K,r,-THyper,sigma,d))
@test_throws(ErrorException, blkprice(spot,K,r,-THyper,sigma))
@test_throws(ErrorException, blsdelta(spot,K,r,-THyper,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-THyper,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-THyper,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-THyper,sigma,d))
@test_throws(ErrorException, blspsi(spot,K,r,-THyper,sigma,d))
@test_throws(ErrorException, blslambda(spot,K,r,-THyper,sigma,d))
@test_throws(ErrorException, blsvanna(spot,K,r,-THyper,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-THyper,sigma,d))

print_with_color(:cyan,"----Testing Negative  Volatility \n")
@test_throws(ErrorException, blsprice(spot,K,r,T,-SigmaHyper,d))
@test_throws(ErrorException, blkprice(spot,K,r,T,-SigmaHyper))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-SigmaHyper,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-SigmaHyper,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-SigmaHyper,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-SigmaHyper,d))
@test_throws(ErrorException, blspsi(spot,K,r,T,-SigmaHyper,d))
@test_throws(ErrorException, blslambda(spot,K,r,T,-SigmaHyper,d))
@test_throws(ErrorException, blsvanna(spot,K,r,T,-SigmaHyper,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-SigmaHyper,d))

print_with_color(:magenta,"Hyper Dual Input Validation Test Passed\n")
