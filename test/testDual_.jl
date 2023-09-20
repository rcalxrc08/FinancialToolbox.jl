using Test
using FinancialToolbox, DualNumbers

#Test Parameters
testToll = 1e-14;

#print_colored("Starting Standard Test\n",:green)
spot = 10;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;
spotDual = dual(spot, 1.0);

toll = 1e-6

#EuropeanCall Option
PriceCall = blsprice(spot, K, r, T, sigma, d);
PriceCallBlack = blkprice(spot, K, r, T, sigma);

df(f, x, dx) = (f(x + dx) - f(x)) / dx
dx = 1e-8;
assert_(value, toll) = @test abs(value) < toll

sigma1 = blsimpv(spot, K, r, T, PriceCall, d);
ResDual = blsimpv(spotDual, K, r, T, PriceCall, d);
DerDF_ = df(spot -> blsimpv(spot, K, r, T, PriceCall, d), spot, dx);

assert_(sigma1 - ResDual, toll)
assert_(DerDF_ - ResDual.epsilon, toll)

sigma1 = blkimpv(spot, K, r, T, PriceCallBlack);
ResDual = blkimpv(spotDual, K, r, T, PriceCallBlack);
DerDF_ = df(spot -> blkimpv(spot, K, r, T, PriceCallBlack), spot, dx);

assert_(sigma1 - ResDual, toll)
assert_(DerDF_ - ResDual.epsilon, toll)

print_colored("Starting DualNumbers Test\n", :green)

#Test Parameters
testToll = 1e-14;
spot = 10;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;

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

########DUAL NUMBERS
DerToll = 1e-13;
#Function definition
#Call
FcallDual(spot) = blsprice(spot, K, r, T, sigma, d);
GcallDual(r) = blsprice(spot, K, r, T, sigma, d);
HcallDual(T) = blsprice(spot, K, r, T, sigma, d);
LcallDual(sigma) = blsprice(spot, K, r, T, sigma, d);
PcallDual(spot) = blsprice(spot, K, r, T, sigma, d) * spot.value / blsprice(spot.value, K, r, T, sigma, d);
VcallDual(sigma) = blsdelta(spot, K, r, T, sigma, d);
#Put
FputDual(spot) = blsprice(spot, K, r, T, sigma, d, false);
GputDual(r) = blsprice(spot, K, r, T, sigma, d, false);
HputDual(T) = blsprice(spot, K, r, T, sigma, d, false);
PputDual(spot) = blsprice(spot, K, r, T, sigma, d, false) * spot.value / blsprice(spot.value, K, r, T, sigma, d, false);
VPutDual(sigma) = blsdelta(spot, K, r, T, sigma, d, false);
#Input
SpotDual = Dual(spot, 1.0);
rDual = Dual(r, 1.0);
TDual = Dual(T, 1.0);
SigmaDual = Dual(sigma, 1.0);

#Automatic Differentiation Test
#TEST
print_colored("--- European Call Sensitivities: DualNumbers\n", :yellow)
print_colored("-----Testing Delta\n", :blue);
assert_(FcallDual(SpotDual).epsilon - DeltaCall, DerToll)
print_colored("-----Testing Rho\n", :blue);
assert_(GcallDual(rDual).epsilon - RhoCall, DerToll)
print_colored("-----Testing Theta\n", :blue);
assert_(-HcallDual(TDual).epsilon - ThetaCall, DerToll)
print_colored("-----Testing Lambda\n", :blue);
assert_(PcallDual(SpotDual).epsilon - LambdaCall, DerToll)
print_colored("-----Testing Vanna\n", :blue);
assert_(VcallDual(SigmaDual).epsilon - VannaCall, DerToll)
#TEST
print_colored("--- European Put Sensitivities: DualNumbers\n", :yellow)
print_colored("-----Testing Delta\n", :blue);
assert_(FputDual(SpotDual).epsilon - DeltaPut, DerToll)
print_colored("-----Testing Rho\n", :blue);
assert_(GputDual(rDual).epsilon - RhoPut, DerToll)
print_colored("-----Testing Theta\n", :blue);
assert_(-HputDual(TDual).epsilon - ThetaPut, DerToll)
print_colored("-----Testing Lambda\n", :blue);
assert_(PputDual(SpotDual).epsilon - LambdaPut, DerToll)
print_colored("-----Testing Vanna\n", :blue);
assert_(VPutDual(SigmaDual).epsilon - VannaPut, DerToll)

print_colored("-----Testing Vega\n", :blue);
assert_(LcallDual(SigmaDual).epsilon - Vega, DerToll)
print_colored("Dual Numbers Test Passed\n", :green)
println("")

#TEST OF INPUT VALIDATION
print_colored("Starting Input Validation Test Dual\n", :magenta)
print_colored("----Testing Negative  Spot Price \n", :cyan)
@test_throws(DomainError, blsprice(-SpotDual, K, r, T, sigma, d))
@test_throws(DomainError, blkprice(-SpotDual, K, r, T, sigma))
@test_throws(DomainError, blsdelta(-SpotDual, K, r, T, sigma, d))
@test_throws(DomainError, blsgamma(-SpotDual, K, r, T, sigma, d))
@test_throws(DomainError, blstheta(-SpotDual, K, r, T, sigma, d))
@test_throws(DomainError, blsrho(-SpotDual, K, r, T, sigma, d))
@test_throws(DomainError, blspsi(-SpotDual, K, r, T, sigma, d))
@test_throws(DomainError, blslambda(-SpotDual, K, r, T, sigma, d))
@test_throws(DomainError, blsvanna(-SpotDual, K, r, T, sigma, d))
@test_throws(DomainError, blsvega(-SpotDual, K, r, T, sigma, d))

print_colored("----Testing Negative  Strike Price \n", :cyan)
KK = Dual(K, 0);
@test_throws(DomainError, blsprice(spot, -KK, r, T, sigma, d))
@test_throws(DomainError, blkprice(spot, -KK, r, T, sigma))
@test_throws(DomainError, blsdelta(spot, -KK, r, T, sigma, d))
@test_throws(DomainError, blsgamma(spot, -KK, r, T, sigma, d))
@test_throws(DomainError, blstheta(spot, -KK, r, T, sigma, d))
@test_throws(DomainError, blsrho(spot, -KK, r, T, sigma, d))
@test_throws(DomainError, blspsi(spot, -KK, r, T, sigma, d))
@test_throws(DomainError, blslambda(spot, -KK, r, T, sigma, d))
@test_throws(DomainError, blsvanna(spot, -KK, r, T, sigma, d))
@test_throws(DomainError, blsvega(spot, -KK, r, T, sigma, d))

print_colored("----Testing Negative  Time to Maturity \n", :cyan)
@test_throws(DomainError, blsprice(spot, K, r, -TDual, sigma, d))
@test_throws(DomainError, blkprice(spot, K, r, -TDual, sigma))
@test_throws(DomainError, blsdelta(spot, K, r, -TDual, sigma, d))
@test_throws(DomainError, blsgamma(spot, K, r, -TDual, sigma, d))
@test_throws(DomainError, blstheta(spot, K, r, -TDual, sigma, d))
@test_throws(DomainError, blsrho(spot, K, r, -TDual, sigma, d))
@test_throws(DomainError, blspsi(spot, K, r, -TDual, sigma, d))
@test_throws(DomainError, blslambda(spot, K, r, -TDual, sigma, d))
@test_throws(DomainError, blsvanna(spot, K, r, -TDual, sigma, d))
@test_throws(DomainError, blsvega(spot, K, r, -TDual, sigma, d))

print_colored("----Testing Negative  Volatility \n", :cyan)
@test_throws(DomainError, blsprice(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blkprice(spot, K, r, T, -SigmaDual))
@test_throws(DomainError, blsdelta(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blsgamma(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blstheta(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blsrho(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blspsi(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blslambda(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blsvanna(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blsvega(spot, K, r, T, -SigmaDual, d))
@test_throws(DomainError, blsimpv(spotDual, K, r, T, -0.2, d))

print_colored("Dual Input Validation Test Passed\n", :magenta)

price_dual = blsprice(SpotDual, K, r, T, sigma, d)
sigma_h1 = blsimpv(SpotDual, K, r, T, price_dual, d)
assert_(sigma_h1.value - sigma, DerToll)
assert_(sigma_h1.epsilon, DerToll)

price_dual2 = blsprice(SpotDual, K, r, T, SigmaDual, d)
sigma_h2 = blsimpv(SpotDual, K, r, T, price_dual2, d)
assert_(sigma_h2.value - SigmaDual.value, DerToll)
assert_(sigma_h2.epsilon - SigmaDual.epsilon, DerToll)