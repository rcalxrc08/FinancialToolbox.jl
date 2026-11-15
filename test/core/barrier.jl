# Barrier options against QuantLib, in-out parity, limits, other float types, input validation. The derivatives are
# checked with every number type and AD backend against DERIVATIVE_CASES (setup.jl).
include(joinpath(@__DIR__, "..", "setup.jl"))

const BARRIER_FUNCTIONS = (blsdownout, blsdownin, blsupout, blsupin)
const (; S0, r, T, σ, d) = BARRIER_POINT

@testset "QuantLib reference values" begin
    for (f, H, K, call, put) in QUANTLIB_BARRIER
        @test abs(f(S0, K, r, T, σ, d, H) - call) < 1e-13
        @test abs(f(S0, K, r, T, σ, d, H, false) - put) < 1e-13
    end
end

@testset "In-out parity" begin
    for K in (80.0, 95.0, 100.0, 105.0, 120.0), FlagIsCall in (true, false)
        vanilla = blsprice(S0, K, r, T, σ, d, FlagIsCall)
        @test blsdownout(S0, K, r, T, σ, d, 95.0, FlagIsCall) + blsdownin(S0, K, r, T, σ, d, 95.0, FlagIsCall) ≈ vanilla
        @test blsupout(S0, K, r, T, σ, d, 105.0, FlagIsCall) + blsupin(S0, K, r, T, σ, d, 105.0, FlagIsCall) ≈ vanilla
    end
end

@testset "Limits" begin
    for K in (80.0, 100.0, 120.0), FlagIsCall in (true, false)
        vanilla = blsprice(S0, K, r, T, σ, d, FlagIsCall)
        # a barrier never reached: the European option
        @test blsdownout(S0, K, r, T, σ, d, 1e-3, FlagIsCall) ≈ vanilla rtol = 1e-8
        @test blsupout(S0, K, r, T, σ, d, 1e4, FlagIsCall) ≈ vanilla rtol = 1e-8
        # the spot on the barrier: knocked out
        @test abs(blsdownout(S0 * (1 + 1e-10), K, r, T, σ, d, S0, FlagIsCall)) < 1e-7
        @test abs(blsupout(S0 * (1 - 1e-10), K, r, T, σ, d, S0, FlagIsCall)) < 1e-7
    end
    # out of the money at the barrier: never pays
    @test blsdownout(S0, 90.0, r, T, σ, d, 95.0, false) == 0
    @test blsupout(S0, 110.0, r, T, σ, d, 105.0) == 0
end

@testset "Other float types" begin
    for (f, H, K, call, put) in QUANTLIB_BARRIER
        x = (S0, K, r, T, σ, d, H)
        @test f(big.(x)...) ≈ call rtol = 1e-13 atol = 1e-13
        @test f(Float32.(x)..., false) isa Float32
        @test f(Float32.(x)..., false) ≈ put rtol = 1e-3 atol = 1e-4
    end
end

@testset "Input validation" begin
    for f in BARRIER_FUNCTIONS
        H = f in (blsdownout, blsdownin) ? 95.0 : 105.0
        @test_throws DomainError f(S0, 100.0, r, T, σ, d, -H)
        # the spot on the other side of the barrier
        @test_throws DomainError f(S0, 100.0, r, T, σ, d, 2 * S0 - H)
        @test_throws DomainError f(S0, 100.0, r, T, σ, d, S0)
        # the checks of the European option
        @test_throws DomainError f(S0, 100.0, r, T, -σ, d, H)
        @test_throws DomainError f(S0, -100.0, r, T, σ, d, H)
    end
end
