using Base.Test
using FinancialModule

#Test Parameters
testToll=1e-14;

print_with_color(:green,"Starting Standard Test\n")
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

print_with_color(:yellow,"---  European Call: Price and Sensitivities\n")
#Standard Test European Call Option
print_with_color(:blue,"-----Testing Price\n");
@test(abs(PriceCall-1.191201316999582)<testToll)
print_with_color(:blue,"-----Testing Delta\n");
@test(abs(DeltaCall-0.572434050810368)<testToll)
print_with_color(:blue,"-----Testing Theta\n");
@test(abs(ThetaCall+0.303776337550247)<testToll)
print_with_color(:blue,"-----Testing Rho\n");
@test(abs(RhoCall-9.066278382208203)<testToll)
print_with_color(:blue,"-----Testing Implied Volatility\n");
@test(abs(SigmaCall-0.2)<testToll)
#Low Xtol
tol_low=1e-12;
tol_high=1e-3;
SigmaLowXTol=blsimpv(spot, K, r, T, PriceCall, d,true,tol_low,tol_high);
@test((abs(blsprice(spot,K,r,T,SigmaLowXTol,d,true)-PriceCall)<tol_high)||abs(SigmaLowXTol-sigma)<tol_low)
#Low Ytol
SigmaLowYTol=blsimpv(spot, K, r, T, PriceCall, d,true,tol_high,tol_low);
@test((abs(blsprice(spot,K,r,T,SigmaLowYTol,d,true)-PriceCall)<tol_high)||abs(SigmaLowYTol-sigma)<tol_low)

print_with_color(:yellow,"---  European Put: Price and Sensitivities\n")
#Standard Test European Put Option
print_with_color(:blue,"-----Testing Price\n");
@test(abs(PricePut-0.997108975455260)<testToll)
print_with_color(:blue,"-----Testing Delta\n");
@test(abs(DeltaPut+0.407764622496387)<testToll)
print_with_color(:blue,"-----Testing Theta\n");
@test(abs(ThetaPut+0.209638317050458)<testToll)
print_with_color(:blue,"-----Testing Rho\n");
@test(abs(RhoPut+10.149510400838260)<testToll)
print_with_color(:blue,"-----Testing Implied Volatility\n");
@test(abs(SigmaPut-0.2)<testToll)

#Standard Test for Common Sensitivities
print_with_color(:blue,"-----Testing Gamma\n");
@test(abs(Gamma-0.135178479404601)<testToll)
print_with_color(:blue,"-----Testing Vega\n");
@test(abs(Vega-5.407139176184034)<testToll)
print_with_color(:green,"Standard Test Passed\n")
println("")



#TEST OF INPUT VALIDATION
print_with_color(:magenta,"Starting Input Validation Test Real\n")
print_with_color(:cyan,"----Testing Negative Spot Price\n")
@test_throws(ErrorException, blsprice(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsimpv(-spot,K,r,T,PriceCall,d))

print_with_color(:cyan,"----Testing Negative Strike Price\n")
@test_throws(ErrorException, blsprice(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsimpv(spot,-K,r,T,PriceCall,d))

print_with_color(:cyan,"----Testing Negative Time to Maturity\n")
@test_throws(ErrorException, blsprice(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsimpv(spot,K,r,-T,PriceCall,d))

print_with_color(:cyan,"----Testing Negative Volatility\n")
@test_throws(ErrorException, blsprice(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-sigma,d))
print_with_color(:cyan,"----Testing Negative Option Price\n")
@test_throws(ErrorException, blsimpv(spot,K,r,T,-PriceCall,d))

print_with_color(:cyan,"----Testing Negative Tollerance\n")
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,-1e-12,1e-12))
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,1e-12,-1e-12))

#Too low tollerance
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,0.0,0.0))

print_with_color(:magenta,"Real Input Validation Test Passed\n")


#End of the Test
