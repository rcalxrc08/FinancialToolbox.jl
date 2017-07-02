using Base.Test
using FinancialModule

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

#Standard Test European Call Option
@test(abs(PriceCall-1.191201316999582)<testToll)
@test(abs(DeltaCall-0.572434050810368)<testToll)
@test(abs(ThetaCall+0.303776337550247)<testToll)
@test(abs(RhoCall-9.066278382208203)<testToll)
@test(abs(SigmaCall-0.2)<testToll)


#Standard Test European Put Option
@test(abs(PricePut-0.997108975455260)<testToll)
@test(abs(DeltaPut+0.407764622496387)<testToll)
@test(abs(ThetaPut+0.209638317050458)<testToll)
@test(abs(RhoPut+10.149510400838260)<testToll)
@test(abs(SigmaPut-0.2)<testToll)

#Standard Test for Common Sensitivities
@test(abs(Gamma-0.135178479404601)<testToll)
@test(abs(Vega-5.407139176184034)<testToll)

## Complex Test with Complex Step Approximation for European Call
#Test parameters
DerToll=1e-13;
di=1e-15;
df(f,x)=f(x+1im*di)/di;
#Function definition
F(spot)=blsprice(spot,K,r,T,sigma,d);
G(r)=blsprice(spot,K,r,T,sigma,d);
H(T)=blsprice(spot,K,r,T,sigma,d);
L(sigma)=blsprice(spot,K,r,T,sigma,d);
#TEST
@test(abs(df(L,sigma).im-Vega)<DerToll)
#
@test(abs(df(F,spot).im-DeltaCall)<DerToll)
@test(abs(df(G,r).im-RhoCall)<DerToll)
@test(abs(-df(H,T).im-ThetaCall)<DerToll)

## Complex Test with Complex Step Approximation for European Put
#Function definition
F1(spot)=blsprice(spot,K,r,T,sigma,d,false);
G1(r)=blsprice(spot,K,r,T,sigma,d,false);
H1(T)=blsprice(spot,K,r,T,sigma,d,false);
#TEST
@test(abs(df(F1,spot).im-DeltaPut)<DerToll)
@test(abs(df(G1,r).im-RhoPut)<DerToll)
@test(abs(-df(H1,T).im-ThetaPut)<DerToll)

#TEST OF INPUT VALIDATION
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

println("All Test Passed")
