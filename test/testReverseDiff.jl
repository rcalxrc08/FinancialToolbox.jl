using Test
using FinancialToolbox, ReverseDiff

#Test Parameters
spot = 10.0;
K = 10;
r = 0.02;
T = 2.0;
sigma = 0.2;
d = 0.01;

toll = 1e-4

#EuropeanCall Option
f_rv(S0) = blsprice(S0[1], K, r, T, sigma, d);
delta_1 = blsdelta(spot, K, r, T, sigma, d);
delta_v = ReverseDiff.gradient(f_rv, [spot])
@test(abs(delta_v[1] - delta_1) < toll)
price = f_rv(spot)
f_rv2(S0) = blsimpv(S0[1], K, r, T, price, d);
delta_v = ReverseDiff.gradient(f_rv2, [spot])
@test(abs(delta_v[1] + 0.10586634302510232) < toll)
# Compiled tapes evaluated away from the point where they were recorded: the instructions of the extension recompute
# their partials in the forward pass (an @grad rule would keep the ones of the recording point)
using ForwardDiff
@testset "ReverseDiff compiled tapes" begin
    x1 = [100.0, 95.0, 0.02, 1.2, 0.2, 0.01]
    x2 = [90.0, 110.0, 0.03, 2.0, 0.3, 0.0]
    p(x, FlagIsCall) = blsprice(x..., FlagIsCall)
    cases = (
        "blsprice call" => (x -> blsprice(x...), x1, x2),
        "blsprice put" => (x -> blsprice(x..., false), x1, x2),
        "blkprice" => (x -> blkprice(x...), x1[1:5], x2[1:5]),
        "blsimpv call" => (x -> blsimpv(x...), [x1[1:4]; p(x1, true); x1[6]], [x2[1:4]; p(x2, true); x2[6]]),
        "blsimpv put" => (x -> blsimpv(x..., false), [x1[1:4]; p(x1, false); x1[6]], [x2[1:4]; p(x2, false); x2[6]]),
        "blkimpv" => (x -> blkimpv(x...), [x1[1:4]; blkprice(x1[1:5]...)], [x2[1:4]; blkprice(x2[1:5]...)]),
        # only some inputs tracked
        "blsimpv, spot and price" => (y -> blsimpv(y[1], 95.0, 0.02, 1.2, y[2], 0.01), [100.0, p(x1, true)], [105.0, blsprice(105.0, 95.0, 0.02, 1.2, 0.25, 0.01)]),
    )
    for (name, (f, a, b)) in cases
        tape = ReverseDiff.compile(ReverseDiff.GradientTape(f, a))
        gradient = similar(a)
        @test ReverseDiff.gradient!(gradient, tape, b) ≈ ForwardDiff.gradient(f, b)
        @test ReverseDiff.gradient!(gradient, tape, a) ≈ ForwardDiff.gradient(f, a)
    end
end
