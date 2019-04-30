using Test
using ForwardDiff;
using FinancialToolbox
Dual_=ForwardDiff.Dual
print_colored("Starting Forward Diff Dual Numbers Test\n",:green)

#Test Parameters
testToll=1e-14;
spot=10;K=10;r=0.02;T=2.0;sigma=0.2;d=0.01;
assert_(value,toll)=@test abs(value)<toll
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
SpotDual=Dual_(spot,1.0);
rDual=Dual_(r,1.0);
TDual=Dual_(T,1.0);
SigmaDual=Dual_(sigma,1.0);

#Automatic Differentiation Test
#TEST
print_colored("--- European Call Sensitivities: DualNumbers\n",:yellow)
print_colored("-----Testing Delta\n",:blue);
assert_(FcallDual(SpotDual).partials[1]-DeltaCall,DerToll)
print_colored("-----Testing Rho\n",:blue);
assert_(GcallDual(rDual).partials[1]-RhoCall,DerToll)
print_colored("-----Testing Theta\n",:blue);
assert_(-HcallDual(TDual).partials[1]-ThetaCall,DerToll)
print_colored("-----Testing Lambda\n",:blue);
assert_(PcallDual(SpotDual).partials[1]-LambdaCall,DerToll)
print_colored("-----Testing Vanna\n",:blue);
assert_(VcallDual(SigmaDual).partials[1]-VannaCall,DerToll)
#TEST
print_colored("--- European Put Sensitivities: DualNumbers\n",:yellow)
print_colored("-----Testing Delta\n",:blue);
assert_(FputDual(SpotDual).partials[1]-DeltaPut,DerToll)
print_colored("-----Testing Rho\n",:blue);
assert_(GputDual(rDual).partials[1]-RhoPut,DerToll)
print_colored("-----Testing Theta\n",:blue);
assert_(-HputDual(TDual).partials[1]-ThetaPut,DerToll)
print_colored("-----Testing Lambda\n",:blue);
assert_(PputDual(SpotDual).partials[1]-LambdaPut,DerToll)
print_colored("-----Testing Vanna\n",:blue);
assert_(VPutDual(SigmaDual).partials[1]-VannaPut,DerToll)

print_colored("-----Testing Vega\n",:blue);
assert_(LcallDual(SigmaDual).partials[1]-Vega,DerToll)
print_colored("Dual Numbers Test Passed\n",:green)
println("")

#TEST OF INPUT VALIDATION
print_colored("Starting Input Validation Test Dual\n",:magenta)
print_colored("----Testing Negative  Spot Price \n",:cyan)
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

print_colored("----Testing Negative  Strike Price \n",:cyan)
KK=Dual_(K,0);
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

print_colored("----Testing Negative  Time to Maturity \n",:cyan)
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

print_colored("----Testing Negative  Volatility \n",:cyan)
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

print_colored("Dual Input Validation Test Passed\n",:magenta)