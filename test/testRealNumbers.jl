using Base.Test
using FinancialToolbox

#Test Parameters
testToll=1e-14;

printstyled("Starting Standard Test\n",color=:green)
spot=10;K=10;r=0.02;T=2.0;sigma=0.2;d=0.01;

#EuropeanCall Option
PriceCall=blsprice(spot,K,r,T,sigma,d);
PriceCallBlack=blkprice(spot,K,r,T,sigma);
DeltaCall=blsdelta(spot,K,r,T,sigma,d);
ThetaCall=blstheta(spot,K,r,T,sigma,d);
RhoCall=blsrho(spot,K,r,T,sigma,d);
VannaCall=blsvanna(spot,K,r,T,sigma,d);
PsiCall=blspsi(spot,K,r,T,sigma,d);
LambdaCall=blslambda(spot,K,r,T,sigma,d);
SigmaCall=blsimpv(spot, K, r, T, PriceCall, d);
SigmaCallBlack=blkimpv(spot, K, r, T, PriceCallBlack);

#EuropeanPut Option
PricePut=blsprice(spot,K,r,T,sigma,d,false);
PricePutBlack=blkprice(spot,K,r,T,sigma,false);
DeltaPut=blsdelta(spot,K,r,T,sigma,d,false);
ThetaPut=blstheta(spot,K,r,T,sigma,d,false);
VannaPut=blsvanna(spot,K,r,T,sigma,d,false);
PsiPut=blspsi(spot,K,r,T,sigma,d,false);
LambdaPut=blslambda(spot,K,r,T,sigma,d,false);
RhoPut=blsrho(spot,K,r,T,sigma,d,false);
SigmaPut=blsimpv(spot,K,r,T,PricePut,d,false);
SigmaPutBlack=blkimpv(spot,K,r,T,PricePutBlack,false);

#Equals for both Options
Gamma=blsgamma(spot,K,r,T,sigma,d);
Vega=blsvega(spot,K,r,T,sigma,d);

printstyled("---  European Call: Price and Sensitivities\n",color=:yellow)
#Standard Test European Call Option
printstyled("-----Testing Price\n",color=:blue);
@test(abs(PriceCall-1.191201316999582)<testToll)
printstyled("-----Testing Black Price\n",color=:blue);
@test(abs(PriceCallBlack-1.080531820066428)<testToll)
printstyled("-----Testing Delta\n",color=:blue);
@test(abs(DeltaCall-0.572434050810368)<testToll)
printstyled("-----Testing Theta\n",color=:blue);
@test(abs(ThetaCall+0.303776337550247)<testToll)
printstyled("-----Testing Rho\n",color=:blue);
@test(abs(RhoCall-9.066278382208203)<testToll)
printstyled("-----Testing Lambda\n",color=:blue);
@test(abs(LambdaCall-4.805518955034612)<testToll)
printstyled("-----Testing Implied Volatility\n",color=:blue);
@test(abs(SigmaCall-0.2)<testToll)
printstyled("-----Testing Implied Volatility Black\n",color=:blue);
@test(abs(SigmaCallBlack-0.2)<testToll)
#Low Xtol for blsimpv
tol_low=1e-16;
tol_high=1e-3;
SigmaLowXTol=blsimpv(spot, K, r, T, PriceCall, d,true,tol_low,tol_high);
printstyled( High Y tol\n",color=:blue,"-----Testing Implied Volatility Low X tol);
@test((abs(blsprice(spot,K,r,T,SigmaLowXTol,d,true)-PriceCall)<tol_high)||abs(SigmaLowXTol-sigma)<tol_low)
#Low Ytol for blsimpv
SigmaLowYTol=blsimpv(spot, K, r, T, PriceCall, d,true,tol_high,tol_low);
printstyled( High X tol\n",color=:blue,"-----Testing Implied Volatility Low Y tol);
@test((abs(blsprice(spot,K,r,T,SigmaLowYTol,d,true)-PriceCall)<tol_low)||abs(SigmaLowYTol-sigma)<tol_high)

printstyled("---  European Put: Price and Sensitivities\n",color=:yellow)
#Standard Test European Put Option
printstyled("-----Testing Price\n",color=:blue);
@test(abs(PricePut-0.997108975455260)<testToll)
printstyled("-----Testing Price Black\n",color=:blue);
@test(abs(PricePutBlack-1.080531820066428)<testToll)
printstyled("-----Testing Delta\n",color=:blue);
@test(abs(DeltaPut+0.407764622496387)<testToll)
printstyled("-----Testing Theta\n",color=:blue);
@test(abs(ThetaPut+0.209638317050458)<testToll)
printstyled("-----Testing Rho\n",color=:blue);
@test(abs(RhoPut+10.149510400838260)<testToll)
printstyled("-----Testing Lambda\n",color=:blue);
@test(abs(LambdaPut+4.089468980160465)<testToll)
printstyled("-----Testing Implied Volatility\n",color=:blue);
@test(abs(SigmaPut-0.2)<testToll)
printstyled("-----Testing Implied Volatility Black\n",color=:blue);
@test(abs(SigmaPutBlack-0.2)<testToll)

#Standard Test for Common Sensitivities
printstyled("-----Testing Gamma\n",color=:blue);
@test(abs(Gamma-0.135178479404601)<testToll)
printstyled("-----Testing Vega\n",color=:blue);
@test(abs(Vega-5.407139176184034)<testToll)
printstyled("Standard Test Passed\n",color=:green)
println("")



#TEST OF INPUT VALIDATION
printstyled("Starting Input Validation Test Real\n",color=:magenta)
printstyled("----Testing Negative Spot Price\n",color=:cyan)
@test_throws(ErrorException, blsprice(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blkprice(-spot,K,r,T,sigma))
@test_throws(ErrorException, blsdelta(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(-spot,K,r,T,sigma,d));
@test_throws(ErrorException, blspsi(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blslambda(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsvanna(-spot,K,r,T,sigma,d))
@test_throws(ErrorException, blsimpv(-spot,K,r,T,PriceCall,d))
@test_throws(ErrorException, blkimpv(-spot,K,r,T,PriceCall))

printstyled("----Testing Negative Strike Price\n",color=:cyan)
@test_throws(ErrorException, blsprice(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blkprice(spot,-K,r,T,sigma))
@test_throws(ErrorException, blsdelta(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blstheta(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsrho(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsvega(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blspsi(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blslambda(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsvanna(spot,-K,r,T,sigma,d))
@test_throws(ErrorException, blsimpv(spot,-K,r,T,PriceCall,d))
@test_throws(ErrorException, blkimpv(spot,-K,r,T,PriceCall))

printstyled("----Testing Negative Time to Maturity\n",color=:cyan)
@test_throws(ErrorException, blsprice(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blkprice(spot,K,r,-T,sigma))
@test_throws(ErrorException, blsdelta(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blspsi(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blslambda(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsvanna(spot,K,r,-T,sigma,d))
@test_throws(ErrorException, blsimpv(spot,K,r,-T,PriceCall,d))
@test_throws(ErrorException, blkimpv(spot,K,r,-T,PriceCall))

printstyled("----Testing Negative Volatility\n",color=:cyan)
@test_throws(ErrorException, blsprice(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blkprice(spot,K,r,T,-sigma))
@test_throws(ErrorException, blsdelta(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsgamma(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blstheta(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsrho(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blspsi(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blslambda(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsvanna(spot,K,r,T,-sigma,d))
@test_throws(ErrorException, blsvega(spot,K,r,T,-sigma,d))
printstyled("----Testing Negative Option Price\n",color=:cyan)
@test_throws(ErrorException, blsimpv(spot,K,r,T,-PriceCall,d))
@test_throws(ErrorException, blkimpv(spot,K,r,T,-PriceCall))

printstyled("----Testing Negative Tollerance\n",color=:cyan)
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,-1e-12,1e-12))
@test_throws(ErrorException, blkimpv(spot,K,r,T,PriceCall,true,-1e-12,1e-12))
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,1e-12,-1e-12))
@test_throws(ErrorException, blkimpv(spot,K,r,T,PriceCall,true,1e-12,-1e-12))

#Too low tollerance
@test_throws(ErrorException, blsimpv(spot,K,r,T,PriceCall,d,true,0.0,0.0))
@test_throws(ErrorException, blkimpv(spot,K,r,T,PriceCall,true,0.0,0.0))

printstyled("Real Input Validation Test Passed\n",color=:magenta)


#End of the Test
