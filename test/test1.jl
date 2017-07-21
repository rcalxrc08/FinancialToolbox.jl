using Base.Test
using FinancialModule

#Test Parameters
testToll=1e-14;
println("")
println("Starting Standard Test")
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

println("")
println("--- European Call Price and Sensitivities")
#Standard Test European Call Option
@test(abs(PriceCall-1.191201316999582)<testToll)
@test(abs(DeltaCall-0.572434050810368)<testToll)
@test(abs(ThetaCall+0.303776337550247)<testToll)
@test(abs(RhoCall-9.066278382208203)<testToll)
@test(abs(SigmaCall-0.2)<testToll)
#Low Xtol
tol_low=1e-12;
tol_high=1e-1;
SigmaLowXTol=blsimpv(spot, K, r, T, PriceCall, d,true,tol_low,tol_high);
@test((abs(blsprice(spot,K,r,T,SigmaLowXTol,d,true)-PriceCall)<tol_high)||abs(SigmaLowXTol-sigma)<tol_low)
#Low Ytol
SigmaLowYTol=blsimpv(spot, K, r, T, PriceCall, d,true,tol_high,tol_low);
@test((abs(blsprice(spot,K,r,T,SigmaLowYTol,d,true)-PriceCall)<tol_high)||abs(SigmaLowYTol-sigma)<tol_low)

println("--- European Put Price and Sensitivities")
#Standard Test European Put Option
@test(abs(PricePut-0.997108975455260)<testToll)
@test(abs(DeltaPut+0.407764622496387)<testToll)
@test(abs(ThetaPut+0.209638317050458)<testToll)
@test(abs(RhoPut+10.149510400838260)<testToll)
@test(abs(SigmaPut-0.2)<testToll)

#Standard Test for Common Sensitivities
@test(abs(Gamma-0.135178479404601)<testToll)
@test(abs(Vega-5.407139176184034)<testToll)
println("Standard Test Passed")
println("")
## Complex Test with Complex Step Approximation for European Call
#Test parameters
println("Starting Complex Number Test")
DerToll=1e-13;
di=1e-15;
df(f,x)=f(x+1im*di)/di;
#Function definition
F(spot)=blsprice(spot,K,r,T,sigma,d);
G(r)=blsprice(spot,K,r,T,sigma,d);
H(T)=blsprice(spot,K,r,T,sigma,d);
L(sigma)=blsprice(spot,K,r,T,sigma,d);
#TEST
println("--- European Call Sensitivities: Complex Step Approximation")
@test(abs(df(F,spot).im-DeltaCall)<DerToll)
@test(abs(df(G,r).im-RhoCall)<DerToll)
@test(abs(-df(H,T).im-ThetaCall)<DerToll)

## Complex Test with Complex Step Approximation for European Put
#Function definition
F1(spot)=blsprice(spot,K,r,T,sigma,d,false);
G1(r)=blsprice(spot,K,r,T,sigma,d,false);
H1(T)=blsprice(spot,K,r,T,sigma,d,false);
#TEST
println("--- European Put Sensitivities: Complex Step Approximation")
@test(abs(df(F1,spot).im-DeltaPut)<DerToll)
@test(abs(df(G1,r).im-RhoPut)<DerToll)
@test(abs(-df(H1,T).im-ThetaPut)<DerToll)

@test(abs(df(L,sigma).im-Vega)<DerToll)
println("Complex Number Test Passed")
println("")

########DUAL NUMBERS
using DualNumbers;
println("Starting Dual Numbers Test")
DerToll=1e-13;
di=1e-15;
#Function definition
sspot=dual(spot,1.0);
rr=dual(r,1.0);
TT=dual(T,1.0);
ssigma=dual(sigma,1.0);
#TEST
println("--- European Call Sensitivities: DualNumbers")
@test(abs(F(sspot).epsilon-DeltaCall)<DerToll)
@test(abs(G(rr).epsilon-RhoCall)<DerToll)
@test(abs(-H(TT).epsilon-ThetaCall)<DerToll)

## Complex Test with Complex Step Approximation for European Put
#TEST
println("--- European Put Sensitivities: DualNumbers")
@test(abs(F1(sspot).epsilon-DeltaPut)<DerToll)
@test(abs(G1(rr).epsilon-RhoPut)<DerToll)
@test(abs(-H1(TT).epsilon-ThetaPut)<DerToll)

@test(abs(L(ssigma).epsilon-Vega)<DerToll)
println("Dual Numbers Test Passed")
println("")

########HYPER DUAL NUMBERS
pkgs = Pkg.installed();
if (pkgs["HyperDualNumbers"]<=VersionNumber(1,0,0))
	Pkg.checkout("HyperDualNumbers")
end
using HyperDualNumbers;
println("Starting Hyper Dual Numbers Test")
DerToll=1e-13;
di=1e-15;
#Function definition
ssspot=hyper(spot,1.0,1.0,0.0);
rrr=hyper(r,1.0,1.0,0.0);
TTT=hyper(T,1.0,1.0,0.0);
sssigma=hyper(sigma,1.0,1.0,0.0);
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
println("Starting Input Validation Test Real")
#Negative Spot Price
@test_throws(ErrorException, blsprice(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsimpv(-spot,K,r,T,PriceCall,d))

#Negative Strike Price
@test_throws(ErrorException, blsprice(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsimpv(spot,-K,r,T,PriceCall,d))

#Negative Time to Maturity
@test_throws(ErrorException, blsprice(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsimpv(spot,K,r,-T,PriceCall,d))

#Negative Volatility
@test_throws(ErrorException, blsprice(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-sigma,d))
#Negative Option Price
@test_throws(ErrorException, blsimpv(spot,K,r,T,-PriceCall,d))

#Negative Tollerance
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,-1e-12,1e-12))
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,1e-12,-1e-12))

#Too low tollerance
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,0.0,0.0))

println("Real Input Validation Test Passed\n")

#TEST OF INPUT VALIDATION
println("Starting Input Validation Test Complex")
#Negative Spot Price
@test_throws(ErrorException, blsprice(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-spot+1im,K,r,T,sigma,d))

#Negative Strike Price
@test_throws(ErrorException, blsprice(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-K+1im,r,T,sigma,d))

#Negative Time to Maturity
@test_throws(ErrorException, blsprice(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-T+1im,sigma,d))

#Negative Volatility
@test_throws(ErrorException, blsprice(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-sigma+1im,d))

println("Complex Input Validation Test Passed\n")

#TEST OF INPUT VALIDATION
println("Starting Input Validation Test Dual")
#Negative Spot Price
@test_throws(ErrorException, blsprice(-sspot,K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(-sspot,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-sspot,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-sspot,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-sspot,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-sspot,K,r,T,sigma,d))

#Negative Strike Price
KK=Dual(K,0);
@test_throws(ErrorException, blsprice(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-KK,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-KK,r,T,sigma,d))

#Negative Time to Maturity
@test_throws(ErrorException, blsprice(spot,K,r,-TT,sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,-TT,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-TT,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-TT,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-TT,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-TT,sigma,d))

#Negative Volatility
@test_throws(ErrorException, blsprice(spot,K,r,T,-ssigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-ssigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-ssigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-ssigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-ssigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-ssigma,d))

println("Dual Input Validation Test Passed\n")


println("Input Validation Test Passed\n")

println("All Test Passed\n")
#End of the Test
