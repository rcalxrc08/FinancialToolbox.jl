if !(VERSION.major == 0 && VERSION.minor <= 6)
    using Test
else
    using Base.Test
end
using FinancialToolbox

print_colored("Starting Hyper Dual Numbers Test\n", :green)

#Test Parameters
testToll = 1e-14;
spot = 10;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;
assert_(value, toll) = @test abs(value) < toll
#EuropeanCall Option
PriceCall = blsprice(spot, K, r, T, sigma, d);
DeltaCall = blsdelta(spot, K, r, T, sigma, d);
ThetaCall = blstheta(spot, K, r, T, sigma, d);
RhoCall = blsrho(spot, K, r, T, sigma, d);
LambdaCall = blslambda(spot, K, r, T, sigma, d);
VannaCall = blsvanna(spot, K, r, T, sigma, d);

#EuropeanPut Option
PricePut = blsprice(spot, K, r, T, sigma, d, false);
DeltaPut = blsdelta(spot, K, r, T, sigma, d, false);
ThetaPut = blstheta(spot, K, r, T, sigma, d, false);
RhoPut = blsrho(spot, K, r, T, sigma, d, false);
LambdaPut = blslambda(spot, K, r, T, sigma, d, false);
VannaPut = blsvanna(spot, K, r, T, sigma, d, false);

#Equals for both Options
Gamma = blsgamma(spot, K, r, T, sigma, d);
Vega = blsvega(spot, K, r, T, sigma, d);

########HYPER DUAL NUMBERS
using HyperDualNumbers;
DerToll = 1e-13;
di = 1e-15;
#Function definition
SpotHyper = hyper(spot, 1.0, 1.0, 0.0);
rHyper = hyper(r, 1.0, 1.0, 0.0);
THyper = hyper(T, 1.0, 1.0, 0.0);
SigmaHyper = hyper(sigma, 1.0, 1.0, 0.0);
KHyper = hyper(K, 1.0, 1.0, 0.0);

#Function definition
#Call
F(spot) = blsprice(spot, K, r, T, sigma, d);
FF(spot) = blsdelta(spot, K, r, T, sigma, d);
G(r) = blsprice(spot, K, r, T, sigma, d);
H(T) = blsprice(spot, K, r, T, sigma, d);
L(sigma) = blsprice(spot, K, r, T, sigma, d);
P(spot) = blsprice(spot, K, r, T, sigma, d) * spot.value / blsprice(spot.value, K, r, T, sigma, d);
V(sigma) = blsdelta(spot, K, r, T, sigma, d);
VV(spot, sigma) = blsprice(spot, K, r, T, sigma, d);
#Put
F1(spot) = blsprice(spot, K, r, T, sigma, d, false);
FF1(spot) = blsdelta(spot, K, r, T, sigma, d, false);
G1(r) = blsprice(spot, K, r, T, sigma, d, false);
H1(T) = blsprice(spot, K, r, T, sigma, d, false);
P1(spot) = blsprice(spot, K, r, T, sigma, d, false) * spot.value / blsprice(spot.value, K, r, T, sigma, d, false);
V1(sigma) = blsdelta(spot, K, r, T, sigma, d, false);
V11(spot, sigma) = blsprice(spot, K, r, T, sigma, d, false);

#TEST
print_colored("--- European Call Sensitivities: HyperDualNumbers\n", :yellow)
print_colored("-----Testing Delta\n", :blue);
assert_(F(SpotHyper).epsilon1 - DeltaCall, DerToll)
print_colored("-----Testing Gamma\n", :blue);
assert_(FF1(SpotHyper).epsilon1 - Gamma, DerToll)
print_colored("-----Testing Gamma  2\n", :blue);
assert_(F(SpotHyper).epsilon12 - Gamma, DerToll)
print_colored("-----Testing Rho\n", :blue);
assert_(G(rHyper).epsilon1 - RhoCall, DerToll)
print_colored("-----Testing Theta\n", :blue);
assert_(-H(THyper).epsilon1 - ThetaCall, DerToll)
print_colored("-----Testing Lambda\n", :blue);
assert_(P(SpotHyper).epsilon1 - LambdaCall, DerToll)
print_colored("-----Testing Vanna\n", :blue);
assert_(V(SigmaHyper).epsilon1 - VannaCall, DerToll)
print_colored("-----Testing Vanna  2\n", :blue);
assert_(VV(hyper(spot, 1, 0, 0), hyper(sigma, 0, 1, 0)).epsilon12 - VannaCall, DerToll)

## Complex Test with Complex Step Approximation for European Put
#TEST
print_colored("--- European Put Sensitivities: HyperDualNumbers\n", :yellow)
print_colored("-----Testing Delta\n", :blue);
assert_(F1(SpotHyper).epsilon1 - DeltaPut, DerToll)
print_colored("-----Testing Rho\n", :blue);
assert_(G1(rHyper).epsilon1 - RhoPut, DerToll)
print_colored("-----Testing Theta\n", :blue);
assert_(-H1(THyper).epsilon1 - ThetaPut, DerToll)
print_colored("-----Testing Lambda\n", :blue);
assert_(P1(SpotHyper).epsilon1 - LambdaPut, DerToll)
print_colored("-----Testing Vanna\n", :blue);
assert_(V1(SigmaHyper).epsilon1 - VannaPut, DerToll)
print_colored("-----Testing Vanna  2\n", :blue);
assert_(V11(hyper(spot, 1, 0, 0), hyper(sigma, 0, 1, 0)).epsilon12 - VannaPut, DerToll)
print_colored("-----Testing Vega\n", :blue);
assert_(L(SigmaHyper).epsilon1 - Vega, DerToll)
print_colored("Hyper Dual Numbers Test Passed\n\n", :green)

#TEST OF INPUT VALIDATION
print_colored("Starting Input Validation Test Hyper Dual Numbers\n", :magenta)
print_colored("----Testing Negative  Spot Price \n", :cyan)
@test_throws(ErrorException, blsprice(-SpotHyper, K, r, T, sigma, d))
@test_throws(ErrorException, blkprice(-SpotHyper, K, r, T, sigma))
@test_throws(ErrorException, blsdelta(-SpotHyper, K, r, T, sigma, d))
@test_throws(ErrorException, blsgamma(-SpotHyper, K, r, T, sigma, d))
@test_throws(ErrorException, blstheta(-SpotHyper, K, r, T, sigma, d))
@test_throws(ErrorException, blsrho(-SpotHyper, K, r, T, sigma, d))
@test_throws(ErrorException, blspsi(-SpotHyper, K, r, T, sigma, d))
@test_throws(ErrorException, blslambda(-SpotHyper, K, r, T, sigma, d))
@test_throws(ErrorException, blsvanna(-SpotHyper, K, r, T, sigma, d))
@test_throws(ErrorException, blsvega(-SpotHyper, K, r, T, sigma, d))

print_colored("----Testing Negative  Strike Price \n", :cyan)
@test_throws(ErrorException, blsprice(spot, -KHyper, r, T, sigma, d))
@test_throws(ErrorException, blkprice(spot, -KHyper, r, T, sigma))
@test_throws(ErrorException, blsdelta(spot, -KHyper, r, T, sigma, d))
@test_throws(ErrorException, blsgamma(spot, -KHyper, r, T, sigma, d))
@test_throws(ErrorException, blstheta(spot, -KHyper, r, T, sigma, d))
@test_throws(ErrorException, blsrho(spot, -KHyper, r, T, sigma, d))
@test_throws(ErrorException, blspsi(spot, -KHyper, r, T, sigma, d))
@test_throws(ErrorException, blslambda(spot, -KHyper, r, T, sigma, d))
@test_throws(ErrorException, blsvanna(spot, -KHyper, r, T, sigma, d))
@test_throws(ErrorException, blsvega(spot, -KHyper, r, T, sigma, d))

print_colored("----Testing Negative  Time to Maturity \n", :cyan)
@test_throws(ErrorException, blsprice(spot, K, r, -THyper, sigma, d))
@test_throws(ErrorException, blkprice(spot, K, r, -THyper, sigma))
@test_throws(ErrorException, blsdelta(spot, K, r, -THyper, sigma, d))
@test_throws(ErrorException, blsgamma(spot, K, r, -THyper, sigma, d))
@test_throws(ErrorException, blstheta(spot, K, r, -THyper, sigma, d))
@test_throws(ErrorException, blsrho(spot, K, r, -THyper, sigma, d))
@test_throws(ErrorException, blspsi(spot, K, r, -THyper, sigma, d))
@test_throws(ErrorException, blslambda(spot, K, r, -THyper, sigma, d))
@test_throws(ErrorException, blsvanna(spot, K, r, -THyper, sigma, d))
@test_throws(ErrorException, blsvega(spot, K, r, -THyper, sigma, d))

print_colored("----Testing Negative  Volatility \n", :cyan)
@test_throws(ErrorException, blsprice(spot, K, r, T, -SigmaHyper, d))
@test_throws(ErrorException, blkprice(spot, K, r, T, -SigmaHyper))
@test_throws(ErrorException, blsdelta(spot, K, r, T, -SigmaHyper, d))
@test_throws(ErrorException, blsgamma(spot, K, r, T, -SigmaHyper, d))
@test_throws(ErrorException, blstheta(spot, K, r, T, -SigmaHyper, d))
@test_throws(ErrorException, blsrho(spot, K, r, T, -SigmaHyper, d))
@test_throws(ErrorException, blspsi(spot, K, r, T, -SigmaHyper, d))
@test_throws(ErrorException, blslambda(spot, K, r, T, -SigmaHyper, d))
@test_throws(ErrorException, blsvanna(spot, K, r, T, -SigmaHyper, d))
@test_throws(ErrorException, blsvega(spot, K, r, T, -SigmaHyper, d))

print_colored("Hyper Dual Input Validation Test Passed\n", :magenta)

price_dual = blsprice(SpotHyper, K, r, T, sigma, d)
sigma_h1 = blsimpv(SpotHyper, K, r, T, price_dual, d)
assert_(sigma_h1.value - sigma, DerToll)
assert_(sigma_h1.epsilon1, DerToll)
assert_(sigma_h1.epsilon12, DerToll)

price_dual2 = blsprice(SpotHyper, K, r, T, SigmaHyper, d)
sigma_h2 = blsimpv(SpotHyper, K, r, T, price_dual2, d)
assert_(sigma_h2.value - SigmaHyper.value, DerToll)
assert_(sigma_h2.epsilon1 - SigmaHyper.epsilon1, DerToll)
assert_(sigma_h2.epsilon12 - SigmaHyper.epsilon12, DerToll)

price_dual2 = blsprice(SpotHyper, KHyper, r, T, SigmaHyper, d)
sigma_h2 = blsimpv(SpotHyper, KHyper, r, T, price_dual2, d)
assert_(sigma_h2.value - SigmaHyper.value, DerToll)
assert_(sigma_h2.epsilon1 - SigmaHyper.epsilon1, DerToll)
assert_(sigma_h2.epsilon12 - SigmaHyper.epsilon12, DerToll)

SigmaHyper = hyper(sigma, 1.0, 2.0, 3.0);
price_dual2 = blsprice(SpotHyper, KHyper, r, T, SigmaHyper, d)
sigma_h2 = blsimpv(SpotHyper, KHyper, r, T, price_dual2, d)
assert_(sigma_h2.value - SigmaHyper.value, DerToll)
assert_(sigma_h2.epsilon1 - SigmaHyper.epsilon1, DerToll)
assert_(sigma_h2.epsilon2 - SigmaHyper.epsilon2, DerToll)
assert_(sigma_h2.epsilon12 - SigmaHyper.epsilon12, DerToll)
