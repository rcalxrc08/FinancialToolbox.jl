using Base.Test
using FinancialModule

@test (1==1)
@test ("1"=="1")

testToll=1e-14;

spot=10;K=10;r=0.02;T=2.0;sigma=0.2;d=0.01;
Price=blsprice(spot,K,r,T,sigma,d);
Delta=blsdelta(spot,K,r,T,sigma,d);
Gamma=blsgamma(spot,K,r,T,sigma,d);
Theta=blstheta(spot,K,r,T,sigma,d);
Rho=blsrho(spot,K,r,T,sigma,d);
Vega=blsvega(spot,K,r,T,sigma,d);
Sigma=blsimpv(spot, K, r, T, Price, d);
@test(abs(Price-1.191201316999582)<testToll)
@test(abs(Delta-0.572434050810368)<testToll)
@test(abs(Gamma-0.135178479404601)<testToll)
@test(abs(Theta+0.303776337550247)<testToll)
@test(abs(Rho-9.066278382208203)<testToll)
@test(abs(Vega-5.407139176184034)<testToll)
@test(abs(Sigma-0.2)<testToll)

#Negative Spot Price
@test_throws(ErrorException, blsprice(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsimpv(-spot,K,r,T,Price,d))

#Negative Strike Price
@test_throws(ErrorException, blsprice(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsimpv(spot,-K,r,T,Price,d))

#Negative Time to Maturity
@test_throws(ErrorException, blsprice(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsimpv(spot,K,r,-T,Price,d))

#Negative Volatility
@test_throws(ErrorException, blsprice(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-sigma,d))

#Negative Option Price
@test_throws(ErrorException, blsimpv(spot,K,r,T,-Price,d))

println("Test Passed")
