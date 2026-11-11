# Prices and sensitivities against the values of the Matlab Financial Toolbox, other float types, input validation.
include(joinpath(@__DIR__, "..", "setup.jl"))

const PRICING_FUNCTIONS = (blsprice, blsbin, blsdelta, blsgamma, blsvega, blsrho, blstheta, blslambda, blspsi, blsvanna)

@testset "Matlab reference values" begin
    (; S0, K, r, T, σ, d) = REFERENCE
    toll = 1e-14
    for (FlagIsCall, ref) in ((true, MATLAB.call), (false, MATLAB.put))
        @test abs(blsprice(S0, K, r, T, σ, d, FlagIsCall) - ref.price) < toll
        @test abs(blsbin(S0, K, r, T, σ, d, FlagIsCall) - ref.binary) < toll
        @test abs(blsdelta(S0, K, r, T, σ, d, FlagIsCall) - ref.delta) < toll
        @test abs(blstheta(S0, K, r, T, σ, d, FlagIsCall) - ref.theta) < toll
        @test abs(blsrho(S0, K, r, T, σ, d, FlagIsCall) - ref.rho) < toll
        @test abs(blslambda(S0, K, r, T, σ, d, FlagIsCall) - ref.lambda) < toll
        @test abs(blkprice(S0, K, r, T, σ, FlagIsCall) - MATLAB.black) < toll
        @test abs(blsimpv(S0, K, r, T, ref.price, d, FlagIsCall) - σ) < toll
        @test abs(blkimpv(S0, K, r, T, MATLAB.black, FlagIsCall) - σ) < toll
    end
    @test abs(blsgamma(S0, K, r, T, σ, d) - MATLAB.gamma) < toll
    @test abs(blsvega(S0, K, r, T, σ, d) - MATLAB.vega) < toll
    # integer inputs
    @test abs(blsprice(10, 10, r, 2, σ, d) - MATLAB.call.price) < toll
end

@testset "Other float types" begin
    x = (REFERENCE.S0, REFERENCE.K, REFERENCE.r, REFERENCE.T, REFERENCE.σ, REFERENCE.d)
    @test blsprice(big.(x)...) ≈ MATLAB.call.price rtol = 1e-14
    @test blsprice(Float32.(x)...) ≈ MATLAB.call.price rtol = 1e-5
    # Float16: rounding of the inputs and cancellation in S0 N(d1) - K N(d2)
    @test blsprice(Float16.(x)...) ≈ MATLAB.call.price rtol = 5e-2
    # Float16 implied volatility at the money (inverse error function) and away from it, against Float32
    for K16 in (100, 110)
        price16 = blsprice(Float16.((100, K16, 0, 1, 0.2, 0))...)
        @test blsimpv(Float16.((100, K16, 0, 1))..., price16, Float16(0)) ≈ blsimpv(Float32.((100, K16, 0, 1, price16, 0))...) rtol = 1e-2
    end
end

@testset "Input validation" begin
    x = [REFERENCE.S0, REFERENCE.K, REFERENCE.r, REFERENCE.T, REFERENCE.σ, REFERENCE.d]
    price = blsprice(x...)
    # negative spot, strike, maturity and volatility
    for i in (1, 2, 4, 5)
        y = copy(x)
        y[i] = -y[i]
        for f in PRICING_FUNCTIONS
            @test_throws DomainError f(y...)
        end
        @test_throws DomainError blkprice(y[1:5]...)
        if i != 5
            @test_throws DomainError blsimpv(y[1:4]..., price, y[6])
            @test_throws DomainError blkimpv(y[1:4]..., price)
        end
    end
    (; S0, K, r, T, d) = REFERENCE
    # prices out of the domain
    @test_throws DomainError blsimpv(S0, K, r, T, -price, d)
    @test_throws DomainError blkimpv(S0, K, r, T, -price)
    @test_throws DomainError blsimpv(S0, K, r, T, 10 * S0, d)
    # tolerance and number of iterations
    @test_throws DomainError blsimpv(S0, K, r, T, price, d, true, -1e-12, 1)
    @test_throws DomainError blkimpv(S0, K, r, T, price, true, -1e-12, 1)
    @test_throws DomainError blsimpv(S0, K, r, T, price, d, true, 1e-12, -1)
    @test_throws DomainError blkimpv(S0, K, r, T, price, true, 1e-12, -1)
end
