using Test
using FinancialToolbox

#Test Parameters
testToll_float64 = 1e-10;

print_colored("Starting Implied Volatility Test\n", :green)
function test_implied_volatility_from_σ(toll, S0, K, r, T, σ, d, FlagIsCall)
    price_t = blsprice(S0, K, r, T, σ, d, FlagIsCall)
    σ_cp = blsimpv(S0, K, r, T, price_t, d, FlagIsCall)
    @test abs(σ_cp - σ) < toll
end
function test_broken_implied_volatility_from_σ(toll, S0, K, r, T, σ, d, FlagIsCall)
    price_t = blsprice(S0, K, r, T, σ, d, FlagIsCall)
    new_σ = blsimpv(S0, K, r, T, price_t, d, FlagIsCall)
    @test_broken abs(new_σ - σ) < toll
end
S0 = 100.0;
K = 100.0;
r = 0.02;
T = 1.2;
σ = 0.2;
d = 0.01;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)
K = 90.0;
d = 0.03;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)
K = 120.0;
r = 0.02;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)
S0 = 160.0;
r = 0.03;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)
S0 = 100.0;
K = 70.0;
r = 0.02;
T = 1.2;
σ = 3.5;
d = 0.01;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)
S0 = 100.0;
K = 70.0;
r = 0.02;
T = 1.2;
σ = 13.5;
d = 0.01;
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)
S0 = 100.0;
K = 100.0;
r = 0.02;
T = 1.0;
σ = 13.5;
d = 0.01;
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)
print_colored("Implied Volatility Test Passed\n", :magenta)

#End of the Test
