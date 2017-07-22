using Base.Test
using FinancialModule

println("Starting Hyper Dual Numbers Test")

#Test Parameters
testToll=1e-14;
spot=10;K=10;r=0.02;T=2.0;sigma=0.2;d=0.01;

#EuropeanCall Option
PriceCall=blsprice(spot,K,r,T,sigma,d);
DeltaCall=blsdelta(spot,K,r,T,sigma,d);
ThetaCall=blstheta(spot,K,r,T,sigma,d);
RhoCall=blsrho(spot,K,r,T,sigma,d);
SigmaCall=blsimpv(spot, K, r, T, PriceCall, d);

#EuropeanPut Option
PricePut=blsprice(spot,K,r,T,sigma,d,false);
DeltaPut=blsdelta(spot,K,r,T,sigma,d,false);
ThetaPut=blstheta(spot,K,r,T,sigma,d,false);
RhoPut=blsrho(spot,K,r,T,sigma,d,false);
SigmaPut=blsimpv(spot, K, r, T, PricePut, d,false);

#Equals for both Options
Gamma=blsgamma(spot,K,r,T,sigma,d);
Vega=blsvega(spot,K,r,T,sigma,d);

########HYPER DUAL NUMBERS
HyperDualNumbersPkgVersion = Pkg.installed("HyperDualNumbers");
if (HyperDualNumbersPkgVersion<=VersionNumber(1,0,0))
#i hope that in the next release they will put also the erf function.
	println("The last release of HyperDualNumbers Module does not support erf function.")
	println("Downloading the master branch ...")
	Pkg.checkout("HyperDualNumbers")
end
using HyperDualNumbers;
DerToll=1e-13;
di=1e-15;
#Function definition
ssspot=hyper(spot,1.0,1.0,0.0);
rrr=hyper(r,1.0,1.0,0.0);
TTT=hyper(T,1.0,1.0,0.0);
sssigma=hyper(sigma,1.0,1.0,0.0);
KKK=hyper(K,1.0,1.0,0.0);


#Function definition
#Call
F(spot)=blsprice(spot,K,r,T,sigma,d);
G(r)=blsprice(spot,K,r,T,sigma,d);
H(T)=blsprice(spot,K,r,T,sigma,d);
L(sigma)=blsprice(spot,K,r,T,sigma,d);
#Put
F1(spot)=blsprice(spot,K,r,T,sigma,d,false);
G1(r)=blsprice(spot,K,r,T,sigma,d,false);
H1(T)=blsprice(spot,K,r,T,sigma,d,false);

#TEST
println("--- European Call Sensitivities: HyperDualNumbers")
@test(abs(F(ssspot).f1-DeltaCall)<DerToll)
@test(abs(F(ssspot).f12-Gamma)<DerToll)
@test(abs(G(rrr).f1-RhoCall)<DerToll)
@test(abs(-H(TTT).f1-ThetaCall)<DerToll)

## Complex Test with Complex Step Approximation for European Put
#TEST
println("--- European Put Sensitivities: HyperDualNumbers")
@test(abs(F1(ssspot).f1-DeltaPut)<DerToll)
@test(abs(G1(rrr).f1-RhoPut)<DerToll)
@test(abs(-H1(TTT).f1-ThetaPut)<DerToll)

@test(abs(L(sssigma).f1-Vega)<DerToll)
println("Hyper Dual Numbers Test Passed")



#TEST OF INPUT VALIDATION
println("Starting Input Validation Test Hyper Dual Numbers")
print_with_color(:blue,"----Testing Negative  Spot Price \n")
@test_throws(ErrorException, blsprice(-ssspot,K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(-ssspot,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-ssspot,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-ssspot,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-ssspot,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-ssspot,K,r,T,sigma,d))

print_with_color(:blue,"----Testing Negative  Strike Price \n")
KK=Dual(K,0);
@test_throws(ErrorException, blsprice(spot,-KKK,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,-KKK,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-KKK,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-KKK,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-KKK,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-KKK,r,T,sigma,d))

print_with_color(:blue,"----Testing Negative  Time to Maturity \n")
@test_throws(ErrorException, blsprice(spot,K,r,-TTT,sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,-TTT,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-TTT,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-TTT,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-TTT,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-TTT,sigma,d))

print_with_color(:blue,"----Testing Negative  Volatility \n")
@test_throws(ErrorException, blsprice(spot,K,r,T,-sssigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-sssigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-sssigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-sssigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-sssigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-sssigma,d))

println("Hyper Dual Input Validation Test Passed\n")

println("Input Validation Test Passed\n")