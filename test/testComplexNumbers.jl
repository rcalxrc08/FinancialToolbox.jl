if !(VERSION.major == 0 && VERSION.minor <= 6)
    using Test
else
    using Base.Test
end
using FinancialToolbox

print_colored("Starting Complex Number Test\n", :green)

#Test Parameters
testToll = 1e-14;
spot = 10;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;
assert_cpx(value, toll) = @test abs(value) < toll

#EuropeanCall Option
PriceCall = blsprice(spot, K, r, T, sigma, d);
DeltaCall = blsdelta(spot, K, r, T, sigma, d);
ThetaCall = blstheta(spot, K, r, T, sigma, d);
LambdaCall = blslambda(spot, K, r, T, sigma, d);
RhoCall = blsrho(spot, K, r, T, sigma, d);

#EuropeanPut Option
PricePut = blsprice(spot, K, r, T, sigma, d, false);
DeltaPut = blsdelta(spot, K, r, T, sigma, d, false);
ThetaPut = blstheta(spot, K, r, T, sigma, d, false);
RhoPut = blsrho(spot, K, r, T, sigma, d, false);
LambdaPut = blslambda(spot, K, r, T, sigma, d, false);

#Equals for both Options
Gamma = blsgamma(spot, K, r, T, sigma, d);
Vega = blsvega(spot, K, r, T, sigma, d);

## Complex Test with Complex Step Approximation for European Call
#Test parameters
DerToll = 1e-13;
di = 1e-15;
df(f, x) = f(x + 1im * di) / di;
#Function definition
Fcall1(spot) = blsprice(spot, K, r, T, sigma, d);
Gcall1(r) = blsprice(spot, K, r, T, sigma, d);
Hcall1(T) = blsprice(spot, K, r, T, sigma, d);
Lcall1(sigma) = blsprice(spot, K, r, T, sigma, d);
Pcall1(spot) = blsprice(spot, K, r, T, sigma, d) * spot.re / blsprice(spot.re, K, r, T, sigma, d);
#TEST
print_colored("--- European Call Sensitivities: Complex Step Approximation\n", :yellow)
print_colored("-----Testing Delta\n", :blue);
assert_cpx(df(Fcall1, spot).im - DeltaCall, DerToll)
print_colored("-----Testing Rho\n", :blue);
assert_cpx(df(Gcall1, r).im - RhoCall, DerToll)
print_colored("-----Testing Theta\n", :blue);
assert_cpx(-df(Hcall1, T).im - ThetaCall, DerToll)
print_colored("-----Testing Lambda\n", :blue);
assert_cpx(df(Pcall1, spot).im - LambdaCall, DerToll)

## Complex Test with Complex Step Approximation for European Put
#Function definition
Fput1(spot) = blsprice(spot, K, r, T, sigma, d, false);
Gput1(r) = blsprice(spot, K, r, T, sigma, d, false);
Hput1(T) = blsprice(spot, K, r, T, sigma, d, false);
Pput1(spot) = blsprice(spot, K, r, T, sigma, d, false) * spot.re / blsprice(spot.re, K, r, T, sigma, d, false);
#TEST
print_colored("--- European Put Sensitivities: Complex Step Approximation\n", :yellow)
print_colored("-----Testing Delta\n", :blue);
assert_cpx(df(Fput1, spot).im - DeltaPut, DerToll)
print_colored("-----Testing Rho\n", :blue);
assert_cpx(df(Gput1, r).im - RhoPut, DerToll)
print_colored("-----Testing Theta\n", :blue);
assert_cpx(-df(Hput1, T).im - ThetaPut, DerToll)
print_colored("-----Testing Lambda\n", :blue);
assert_cpx(df(Pput1, spot).im - LambdaPut, DerToll)

print_colored("-----Testing Vega\n", :blue);
assert_cpx(df(Lcall1, sigma).im - Vega, DerToll)
print_colored("Complex Number Test Passed\n", :green)
println("")

#TEST OF INPUT VALIDATION
print_colored("Starting Input Validation Test Complex\n", :magenta)
print_colored("----Testing Negative  Spot Price \n", :cyan)
@test_throws(DomainError, blsprice(-spot + 1im, K, r, T, sigma, d))
@test_throws(DomainError, blkprice(-spot + 1im, K, r, T, sigma))
@test_throws(DomainError, blsdelta(-spot + 1im, K, r, T, sigma, d))
@test_throws(DomainError, blsgamma(-spot + 1im, K, r, T, sigma, d))
@test_throws(DomainError, blstheta(-spot + 1im, K, r, T, sigma, d))
@test_throws(DomainError, blsrho(-spot + 1im, K, r, T, sigma, d))
@test_throws(DomainError, blspsi(-spot + 1im, K, r, T, sigma, d))
@test_throws(DomainError, blslambda(-spot + 1im, K, r, T, sigma, d))
@test_throws(DomainError, blsvanna(-spot + 1im, K, r, T, sigma, d))
@test_throws(DomainError, blsvega(-spot + 1im, K, r, T, sigma, d))

print_colored("----Testing Negative  Strike Price \n", :cyan)
@test_throws(DomainError, blsprice(spot, -K + 1im, r, T, sigma, d))
@test_throws(DomainError, blkprice(spot, -K + 1im, r, T, sigma))
@test_throws(DomainError, blsdelta(spot, -K + 1im, r, T, sigma, d))
@test_throws(DomainError, blsgamma(spot, -K + 1im, r, T, sigma, d))
@test_throws(DomainError, blstheta(spot, -K + 1im, r, T, sigma, d))
@test_throws(DomainError, blsrho(spot, -K + 1im, r, T, sigma, d))
@test_throws(DomainError, blspsi(spot, -K + 1im, r, T, sigma, d))
@test_throws(DomainError, blslambda(spot, -K + 1im, r, T, sigma, d))
@test_throws(DomainError, blsvanna(spot, -K + 1im, r, T, sigma, d))
@test_throws(DomainError, blsvega(spot, -K + 1im, r, T, sigma, d))

print_colored("----Testing Negative  Time to Maturity \n", :cyan)
@test_throws(DomainError, blsprice(spot, K, r, -T + 1im, sigma, d))
@test_throws(DomainError, blkprice(spot, K, r, -T + 1im, sigma))
@test_throws(DomainError, blsdelta(spot, K, r, -T + 1im, sigma, d))
@test_throws(DomainError, blsgamma(spot, K, r, -T + 1im, sigma, d))
@test_throws(DomainError, blstheta(spot, K, r, -T + 1im, sigma, d))
@test_throws(DomainError, blsrho(spot, K, r, -T + 1im, sigma, d))
@test_throws(DomainError, blspsi(spot, K, r, -T + 1im, sigma, d))
@test_throws(DomainError, blslambda(spot, K, r, -T + 1im, sigma, d))
@test_throws(DomainError, blsvanna(spot, K, r, -T + 1im, sigma, d))
@test_throws(DomainError, blsvega(spot, K, r, -T + 1im, sigma, d))

print_colored("----Testing Negative  Volatility \n", :cyan)
@test_throws(DomainError, blsprice(spot, K, r, T, -sigma + 1im, d))
@test_throws(DomainError, blkprice(spot, K, r, T, -sigma + 1im))
@test_throws(DomainError, blsdelta(spot, K, r, T, -sigma + 1im, d))
@test_throws(DomainError, blsgamma(spot, K, r, T, -sigma + 1im, d))
@test_throws(DomainError, blstheta(spot, K, r, T, -sigma + 1im, d))
@test_throws(DomainError, blsrho(spot, K, r, T, -sigma + 1im, d))
@test_throws(DomainError, blspsi(spot, K, r, T, -sigma + 1im, d))
@test_throws(DomainError, blslambda(spot, K, r, T, -sigma + 1im, d))
@test_throws(DomainError, blsvanna(spot, K, r, T, -sigma + 1im, d))
@test_throws(DomainError, blsvega(spot, K, r, T, -sigma + 1im, d))

print_colored("Complex Input Validation Test Passed\n", :magenta)

## Implied Volatility with Complex Numbers: analytic continuation of the real implied volatility
print_colored("Starting Complex Implied Volatility Test\n", :green)
VegaImpv = blsvega(spot, K, r, T, sigma, d)
for FlagIsCall in (true, false)
    PriceImpv = blsprice(spot, K, r, T, sigma, d, FlagIsCall)
    #Complex step approximation: dσ/dθ = -(∂Price/∂θ) / vega
    @test abs(df(x -> blsimpv(x, K, r, T, PriceImpv, d, FlagIsCall), spot).im + blsdelta(spot, K, r, T, sigma, d, FlagIsCall) / VegaImpv) < DerToll
    @test abs(df(x -> blsimpv(spot, K, r, T, x, d, FlagIsCall), PriceImpv).im - 1 / VegaImpv) < DerToll
    @test abs(df(x -> blsimpv(spot, K, x, T, PriceImpv, d, FlagIsCall), r).im + blsrho(spot, K, r, T, sigma, d, FlagIsCall) / VegaImpv) < DerToll
    #Large imaginary parts: still a root of blsprice(σ) = price
    PriceComplex = PriceImpv + 1im
    @test abs(blsprice(spot, K, r, T, blsimpv(spot, K, r, T, PriceComplex, d, FlagIsCall), d, FlagIsCall) - PriceComplex) < 1e-12
end
#Real parts outside the domain, imaginary parts too large for Newton
@test_throws(DomainError, blsimpv(spot, K, r, T, 1000.0 + 1im, d))
@test_throws(DomainError, blsimpv(spot, K, r, T, blsprice(spot, K, r, T, sigma, d) + 1000im, d))
print_colored("Complex Implied Volatility Test Passed\n", :green)
