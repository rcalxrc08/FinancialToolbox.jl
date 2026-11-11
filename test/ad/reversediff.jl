# ReverseDiff: blsprice, blkprice, blsimpv and blkimpv are single tape instructions written by hand. Compiled tapes are
# evaluated away from the point where they were recorded: the instructions recompute their partials in the forward
# pass (an @grad rule would keep the ones of the recording point). Against ForwardDiff.
include(joinpath(@__DIR__, "..", "setup.jl"))
using ReverseDiff, ForwardDiff

@testset "ReverseDiff" begin
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
    @testset "$name" for (name, (f, a, b)) in cases
        g_a, g_b = ForwardDiff.gradient(f, a), ForwardDiff.gradient(f, b)
        @test ReverseDiff.gradient(f, a) ≈ g_a
        tape = ReverseDiff.compile(ReverseDiff.GradientTape(f, a))
        gradient = similar(a)
        @test ReverseDiff.gradient!(gradient, tape, b) ≈ g_b
        @test ReverseDiff.gradient!(gradient, tape, a) ≈ g_a
    end
end
