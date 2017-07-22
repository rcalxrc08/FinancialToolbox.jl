using Base.Test
using FinancialModule

println("Starting Complex Number Test")

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

## Complex Test with Complex Step Approximation for European Call
#Test parameters
DerToll=1e-13;
di=1e-15;
df(f,x)=f(x+1im*di)/di;
#Function definition
Fcall1(spot)=blsprice(spot,K,r,T,sigma,d);
Gcall1(r)=blsprice(spot,K,r,T,sigma,d);
Hcall1(T)=blsprice(spot,K,r,T,sigma,d);
Lcall1(sigma)=blsprice(spot,K,r,T,sigma,d);
#TEST
print_with_color(:green,"--- European Call Sensitivities: Complex Step Approximation\n")
@test(abs(df(Fcall1,spot).im-DeltaCall)<DerToll)
@test(abs(df(Gcall1,r).im-RhoCall)<DerToll)
@test(abs(-df(Hcall1,T).im-ThetaCall)<DerToll)

## Complex Test with Complex Step Approximation for European Put
#Function definition
Fput1(spot)=blsprice(spot,K,r,T,sigma,d,false);
Gput1(r)=blsprice(spot,K,r,T,sigma,d,false);
Hput1(T)=blsprice(spot,K,r,T,sigma,d,false);
#TEST
print_with_color(:green,"--- European Put Sensitivities: Complex Step Approximation\n")
@test(abs(df(Fput1,spot).im-DeltaPut)<DerToll)
@test(abs(df(Gput1,r).im-RhoPut)<DerToll)
@test(abs(-df(Hput1,T).im-ThetaPut)<DerToll)

@test(abs(df(Lcall1,sigma).im-Vega)<DerToll)
println("Complex Number Test Passed")
println("")

#TEST OF INPUT VALIDATION
println("Starting Input Validation Test Complex")
print_with_color(:blue,"----Testing Negative  Spot Price \n")
@test_throws(ErrorException, blsprice(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-spot+1im,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-spot+1im,K,r,T,sigma,d))

print_with_color(:blue,"----Testing Negative  Strike Price \n")
@test_throws(ErrorException, blsprice(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-K+1im,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-K+1im,r,T,sigma,d))

print_with_color(:blue,"----Testing Negative  Time to Maturity \n")
@test_throws(ErrorException, blsprice(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-T+1im,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-T+1im,sigma,d))

print_with_color(:blue,"----Testing Negative  Volatility \n")
@test_throws(ErrorException, blsprice(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-sigma+1im,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-sigma+1im,d))

println("Complex Input Validation Test Passed\n")
