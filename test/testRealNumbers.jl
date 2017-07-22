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
tol_high=1e-3;
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


#End of the Test
