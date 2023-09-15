using Test
using FinancialToolbox

#Test Parameters
testToll_float64 = 1e-10;

print_colored("Starting Implied Volatility Test\n", :green)
function test_implied_volatility_from_σ(toll, S0, K, r, T, σ, FlagIsCall)
    price_t = blkprice(S0, K, r, T, σ, FlagIsCall)
    σ_cp = blkimpv(S0, K, r, T, price_t, FlagIsCall)
    @test abs(σ_cp - σ) < toll
end
function test_broken_implied_volatility_from_σ(toll, S0, K, r, T, σ, FlagIsCall)
    price_t = blkprice(S0, K, r, T, σ, FlagIsCall)
    @test_broken abs(blkimpv(S0, K, r, T, price_t, FlagIsCall) - σ) < toll
end
S0 = 100.0;
K = 100.0;
r = 0.02;
T = 1.2;
σ = 0.2;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, false)
K = 90.0;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, false)
K = 120.0;
r = 0.02;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, false)
S0 = 160.0;
r = 0.03;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, false)
S0 = 100.0;
K = 70.0;
r = 0.02;
T = 1.2;
σ = 3.5;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, false)
S0 = 100.0;
K = 70.0;
r = 0.02;
T = 1.2;
σ = 13.5;
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, true)
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, false)
S0 = 100.0;
K = 100.0;
r = 0.02;
T = 1.0;
σ = 13.5;
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, true)
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, false)
print_colored("Implied Volatility Test Passed\n", :magenta)

#End of the Test
