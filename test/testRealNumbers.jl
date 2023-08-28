if !(VERSION.major == 0 && VERSION.minor <= 6)
    using Test
else
    using Base.Test
end
using FinancialToolbox

#Test Parameters
testToll = 1e-14;

print_colored("Starting Standard Test\n", :green)
spot = 10;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;
assert_(value, toll) = @test abs(value) < toll
#EuropeanCall Option
PriceCall = blsprice(spot, K, r, T, sigma, d);
PriceCallBig = blsprice(big.([spot, K, r, T, sigma, d])...);
PriceCall32 = blsprice(Float32.([spot, K, r, T, sigma, d])...);
PriceCall16 = blsprice(Float16.([spot, K, r, T, sigma, d])...);
PriceBinaryCall = blsbin(spot, K, r, T, sigma, d);
PriceCallBlack = blkprice(spot, K, r, T, sigma);
DeltaCall = blsdelta(spot, K, r, T, sigma, d);
ThetaCall = blstheta(spot, K, r, T, sigma, d);
RhoCall = blsrho(spot, K, r, T, sigma, d);
VannaCall = blsvanna(spot, K, r, T, sigma, d);
PsiCall = blspsi(spot, K, r, T, sigma, d);
LambdaCall = blslambda(spot, K, r, T, sigma, d);
SigmaCall = blsimpv(spot, K, r, T, PriceCall, d);
SigmaCallBlack = blkimpv(spot, K, r, T, PriceCallBlack);

#EuropeanPut Option
PricePut = blsprice(spot, K, r, T, sigma, d, false);
PriceBinaryPut = blsbin(spot, K, r, T, sigma, d, false);
PricePutBlack = blkprice(spot, K, r, T, sigma, false);
DeltaPut = blsdelta(spot, K, r, T, sigma, d, false);
ThetaPut = blstheta(spot, K, r, T, sigma, d, false);
VannaPut = blsvanna(spot, K, r, T, sigma, d, false);
PsiPut = blspsi(spot, K, r, T, sigma, d, false);
LambdaPut = blslambda(spot, K, r, T, sigma, d, false);
RhoPut = blsrho(spot, K, r, T, sigma, d, false);
SigmaPut = blsimpv(spot, K, r, T, PricePut, d, false);
SigmaPutBlack = blkimpv(spot, K, r, T, PricePutBlack, false);

#Equals for both Options
Gamma = blsgamma(spot, K, r, T, sigma, d);
Vega = blsvega(spot, K, r, T, sigma, d);

print_colored("---  European Call: Price and Sensitivities\n", :yellow)
#Standard Test European Call Option
print_colored("-----Testing Price\n", :blue);
assert_(PriceCall - 1.191201316999582, testToll)
assert_(PriceCall - 1.191201316999582, testToll)
assert_(PriceCall - 1.191201316999582, testToll)
print_colored("-----Testing Price Binary\n", :blue);
assert_(PriceBinaryCall - 0.4533139191104102, testToll)
print_colored("-----Testing Black Price\n", :blue);
assert_(PriceCallBlack - 1.080531820066428, testToll)
print_colored("-----Testing Delta\n", :blue);
assert_(DeltaCall - 0.572434050810368, testToll)
print_colored("-----Testing Theta\n", :blue);
assert_(ThetaCall + 0.303776337550247, testToll)
print_colored("-----Testing Rho\n", :blue);
assert_(RhoCall - 9.066278382208203, testToll)
print_colored("-----Testing Lambda\n", :blue);
assert_(LambdaCall - 4.805518955034612, testToll)
print_colored("-----Testing Implied Volatility\n", :blue);
assert_(SigmaCall - 0.2, testToll)
print_colored("-----Testing Implied Volatility Black\n", :blue);
assert_(SigmaCallBlack - 0.2, testToll)
#Low Xtol for blsimpv
tol_low = 1e-16;
tol_high = 1e-3;
SigmaLowXTol = blsimpv(spot, K, r, T, PriceCall, d, true, tol_low, tol_high);
print_colored("-----Testing Implied Volatility Low X tol, High Y tol\n", :blue);
@test((abs(blsprice(spot, K, r, T, SigmaLowXTol, d, true) - PriceCall) < tol_high) || abs(SigmaLowXTol - sigma) < tol_low)
#Low Ytol for blsimpv
SigmaLowYTol = blsimpv(spot, K, r, T, PriceCall, d, true, tol_high, tol_low);
print_colored("-----Testing Implied Volatility Low Y tol, High X tol\n", :blue);
@test((abs(blsprice(spot, K, r, T, SigmaLowYTol, d, true) - PriceCall) < tol_low) || abs(SigmaLowYTol - sigma) < tol_high)

print_colored("---  European Put: Price and Sensitivities\n", :yellow)
#Standard Test European Put Option
print_colored("-----Testing Price\n", :blue);
assert_(PricePut - 0.997108975455260, testToll)
print_colored("-----Testing Binary Price\n", :blue);
assert_(PriceBinaryPut - 0.507475520041913, testToll)
print_colored("-----Testing Price Black\n", :blue);
assert_(PricePutBlack - 1.080531820066428, testToll)
print_colored("-----Testing Delta\n", :blue);
assert_(DeltaPut + 0.407764622496387, testToll)
print_colored("-----Testing Theta\n", :blue);
assert_(ThetaPut + 0.209638317050458, testToll)
print_colored("-----Testing Rho\n", :blue);
assert_(RhoPut + 10.149510400838260, testToll)
print_colored("-----Testing Lambda\n", :blue);
assert_(LambdaPut + 4.089468980160465, testToll)
print_colored("-----Testing Implied Volatility\n", :blue);
assert_(SigmaPut - 0.2, testToll)
print_colored("-----Testing Implied Volatility Black\n", :blue);
assert_(SigmaPutBlack - 0.2, testToll)

#Standard Test for Common Sensitivities
print_colored("-----Testing Gamma\n", :blue);
assert_(Gamma - 0.135178479404601, testToll)
print_colored("-----Testing Vega\n", :blue);
assert_(Vega - 5.407139176184034, testToll)
print_colored("Standard Test Passed\n", :green)
println("")

#TEST OF INPUT VALIDATION
print_colored("Starting Input Validation Test Real\n", :magenta)
print_colored("----Testing Negative Spot Price\n", :cyan)
@test_throws(ErrorException, blsprice(-spot, K, r, T, sigma, d))
@test_throws(ErrorException, blkprice(-spot, K, r, T, sigma))
@test_throws(ErrorException, blsdelta(-spot, K, r, T, sigma, d))
@test_throws(ErrorException, blsgamma(-spot, K, r, T, sigma, d))
@test_throws(ErrorException, blstheta(-spot, K, r, T, sigma, d))
@test_throws(ErrorException, blsrho(-spot, K, r, T, sigma, d))
@test_throws(ErrorException, blsvega(-spot, K, r, T, sigma, d));
@test_throws(ErrorException, blspsi(-spot, K, r, T, sigma, d))
@test_throws(ErrorException, blslambda(-spot, K, r, T, sigma, d))
@test_throws(ErrorException, blsvanna(-spot, K, r, T, sigma, d))
@test_throws(ErrorException, blsimpv(-spot, K, r, T, PriceCall, d))
@test_throws(ErrorException, blkimpv(-spot, K, r, T, PriceCall))

print_colored("----Testing Negative Strike Price\n", :cyan)
@test_throws(ErrorException, blsprice(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blkprice(spot, -K, r, T, sigma))
@test_throws(ErrorException, blsdelta(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blsgamma(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blstheta(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blsrho(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blsvega(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blspsi(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blslambda(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blsvanna(spot, -K, r, T, sigma, d))
@test_throws(ErrorException, blsimpv(spot, -K, r, T, PriceCall, d))
@test_throws(ErrorException, blkimpv(spot, -K, r, T, PriceCall))

print_colored("----Testing Negative Time to Maturity\n", :cyan)
@test_throws(ErrorException, blsprice(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blkprice(spot, K, r, -T, sigma))
@test_throws(ErrorException, blsdelta(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blsgamma(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blstheta(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blsrho(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blsvega(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blspsi(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blslambda(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blsvanna(spot, K, r, -T, sigma, d))
@test_throws(ErrorException, blsimpv(spot, K, r, -T, PriceCall, d))
@test_throws(ErrorException, blkimpv(spot, K, r, -T, PriceCall))

print_colored("----Testing Negative Volatility\n", :cyan)
@test_throws(ErrorException, blsprice(spot, K, r, T, -sigma, d))
@test_throws(ErrorException, blkprice(spot, K, r, T, -sigma))
@test_throws(ErrorException, blsdelta(spot, K, r, T, -sigma, d))
@test_throws(ErrorException, blsgamma(spot, K, r, T, -sigma, d))
@test_throws(ErrorException, blstheta(spot, K, r, T, -sigma, d))
@test_throws(ErrorException, blsrho(spot, K, r, T, -sigma, d))
@test_throws(ErrorException, blspsi(spot, K, r, T, -sigma, d))
@test_throws(ErrorException, blslambda(spot, K, r, T, -sigma, d))
@test_throws(ErrorException, blsvanna(spot, K, r, T, -sigma, d))
@test_throws(ErrorException, blsvega(spot, K, r, T, -sigma, d))
print_colored("----Testing Negative Option Price\n", :cyan)
@test_throws(ErrorException, blsimpv(spot, K, r, T, -PriceCall, d))
@test_throws(ErrorException, blkimpv(spot, K, r, T, -PriceCall))

print_colored("----Testing Negative Tollerance\n", :cyan)
@test_throws(ErrorException, blsimpv(spot, K, r, T, PriceCall, d, true, -1e-12, 1e-12))
@test_throws(ErrorException, blkimpv(spot, K, r, T, PriceCall, true, -1e-12, 1e-12))
@test_throws(ErrorException, blsimpv(spot, K, r, T, PriceCall, d, true, 1e-12, -1e-12))
@test_throws(ErrorException, blkimpv(spot, K, r, T, PriceCall, true, 1e-12, -1e-12))

#Too low tollerance
# @test_throws(ErrorException, blsimpv(spot, K, r, T, PriceCall, d, true, 0.0, 0.0))
# @test_throws(ErrorException, blkimpv(spot, K, r, T, PriceCall, true, 0.0, 0.0))

print_colored("Real Input Validation Test Passed\n", :magenta)

#End of the Test
