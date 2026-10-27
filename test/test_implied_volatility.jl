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

@test_throws(DomainError, blsimpv(S0, K, r, T, S0 * 10, d))

#New test from issue #21
S0 = 4753.63;
K = 4085.0;
r = 0.0525;
T = 0.13870843734533175;
price_1 = 701.3994
d = 0.0
σ = blsimpv(S0, K, r, T, price_1, d);
@test !isnan(σ)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)

S0 = 100.0;
K = 10.0;
r = 0.02;
T = 1.2;
σ = 0.2;
d = 0.01;
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true) # deep in the money: the time value (~1e-30) is below the precision of the price, σ is not recoverable
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)

S0 = 10.0;
K = 100.0;
r = 0.02;
T = 1.2;
σ = 0.2;
d = 0.01;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_broken_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false) # deep in the money: the time value (~1e-30) is below the precision of the price, σ is not recoverable

S0 = 100.0;
K = 100.0;
r = 0.2;
T = 1.2;
σ = 0.2;
d = 0.01;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)

S0 = 100.0;
K = 100.0;
r = 0.02;
T = 0.2;
σ = 0.2;
d = 0.01;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)

S0 = 100.0;
K = 100.0;
r = 0.02;
T = 1.2;
σ = 0.2;
d = 0.1;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)

S0 = 100.0;
K = 100.0;
r = 0.02;
T = 10.2;
σ = 0.2;
d = 0.01;
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)

# Accuracy on a grid of moneyness, maturities and volatilities (calls and puts, in and out of the money):
# the error must be within a small factor of the attainable accuracy (1 + κ)·ε, κ = price / (vega·σ).
let max_excess = 0.0
    F = 100.0
    for FlagIsCall in (true, false), k in exp.(range(log(0.2), log(5.0), length = 21)), T in (0.01, 0.25, 2.0, 10.0), σ in (0.01, 0.05, 0.2, 0.5, 1.0, 2.0, 3.0)
        K = F * k
        price_big, κ = setprecision(BigFloat, 256) do
            p = FinancialToolbox.blprice_impl(big(F), big(K), big(T), big(σ), FlagIsCall)
            p, Float64(p / (FinancialToolbox.blvega_impl(big(F), big(K), big(T), big(σ)) * σ))
        end
        price = Float64(price_big)
        (price > max(FlagIsCall ? F - K : K - F, 0.0) && price < (FlagIsCall ? F : K)) || continue
        σ_impl = FinancialToolbox.blimpv(F, K, T, price, FlagIsCall, 1e-14, 4)
        max_excess = max(max_excess, abs(σ_impl - σ) / σ / (eps() * (1 + κ)))
    end
    @test max_excess < 10
end

# Float32 is computed in Float32; the reference is the BigFloat implied volatility of the Float32 inputs
let max_excess = 0.0
    F = 100.0f0
    for FlagIsCall in (true, false), k in exp.(range(log(0.2), log(5.0), length = 11)), T in (0.01f0, 2.0f0), σ in (0.05f0, 0.2f0, 1.0f0)
        K = Float32(F * k)
        price = Float32(FinancialToolbox.blprice_impl(big(F), big(K), big(T), big(σ), FlagIsCall))
        intrinsic = max(FlagIsCall ? F - K : K - F, 0.0f0)
        # prices whose normalised time value is subnormal have too few significant bits
        (price > intrinsic && price < (FlagIsCall ? F : K) && (price - intrinsic) / sqrt(F * K) > floatmin(Float32)) || continue
        σ_ref, κ = setprecision(BigFloat, 256) do
            s = FinancialToolbox.blimpv(big(F), big(K), big(T), big(price), FlagIsCall, 1e-14, 8)
            s, Float64(price / (FinancialToolbox.blvega_impl(big(F), big(K), big(T), s) * s))
        end
        σ_impl = @inferred FinancialToolbox.blimpv(F, K, T, price, FlagIsCall, 1e-7, 4)
        @test σ_impl isa Float32
        max_excess = max(max_excess, Float64(abs(σ_impl - σ_ref) / σ_ref) / (eps(Float32) * (1 + κ)))
    end
    @test max_excess < 10
end

# S0 = 1000000.0;
# K = 1.0;
# r = 0.2;
# T = 1.2;
# σ = 0.2;
# d = 0.01;
# test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, true)
# test_implied_volatility_from_σ(testToll_float64, S0, K, r, T, σ, d, false)
print_colored("Implied Volatility Test Passed\n", :magenta)

#End of the Test
