# Complex numbers: sensitivities by the complex step approximation, input validation on the real parts, and the
# implied volatility as the analytic continuation of the real one.
include(joinpath(@__DIR__, "..", "setup.jl"))

const h = 1e-15
# complex step: f'(x) = imag(f(x + ih)) / h, exact up to O(h²)
complex_step(f, x) = imag(f(complex(x, h))) / h

@testset "Complex step sensitivities" begin
    (; S0, K, r, T, σ, d) = REFERENCE
    toll = 1e-13
    for FlagIsCall in (true, false)
        g = closed_form_greeks(FlagIsCall)
        @test abs(complex_step(x -> blsprice(x, K, r, T, σ, d, FlagIsCall), S0) - g.delta) < toll
        @test abs(complex_step(x -> blsprice(S0, K, x, T, σ, d, FlagIsCall), r) - g.rho) < toll
        @test abs(-complex_step(x -> blsprice(S0, K, r, x, σ, d, FlagIsCall), T) - g.theta) < toll
        @test abs(complex_step(x -> blsprice(S0, K, r, T, x, d, FlagIsCall), σ) - g.vega) < toll
        @test abs(complex_step(x -> blsprice(S0, K, r, T, σ, x, FlagIsCall), d) - g.psi) < toll
    end
end

@testset "Input validation" begin
    x = Any[REFERENCE.S0, REFERENCE.K, REFERENCE.r, REFERENCE.T, REFERENCE.σ, REFERENCE.d]
    # negative real parts of spot, strike, maturity and volatility
    for i in (1, 2, 4, 5)
        y = copy(x)
        y[i] = complex(-y[i], 1.0)
        @test_throws DomainError blsprice(y...)
        @test_throws DomainError blkprice(y[1:5]...)
        @test_throws DomainError blsdelta(y...)
    end
end

@testset "Implied volatility" begin
    (; S0, K, r, T, σ, d) = REFERENCE
    toll = 1e-13
    for FlagIsCall in (true, false)
        g = closed_form_greeks(FlagIsCall)
        price = g.price
        # dσ/dθ = -(∂price/∂θ) / vega, dσ/dprice = 1 / vega
        @test abs(complex_step(x -> blsimpv(x, K, r, T, price, d, FlagIsCall), S0) + g.delta / g.vega) < toll
        @test abs(complex_step(x -> blsimpv(S0, K, r, T, x, d, FlagIsCall), price) - 1 / g.vega) < toll
        @test abs(complex_step(x -> blsimpv(S0, K, x, T, price, d, FlagIsCall), r) + g.rho / g.vega) < toll
        # large imaginary parts: still a root of blsprice(σ) = price
        price_complex = price + 1im
        @test abs(blsprice(S0, K, r, T, blsimpv(S0, K, r, T, price_complex, d, FlagIsCall), d, FlagIsCall) - price_complex) < 1e-12
    end
    # real parts outside the domain, imaginary parts too large for Newton
    @test_throws DomainError blsimpv(S0, K, r, T, 1000.0 + 1im, d)
    @test_throws DomainError blsimpv(S0, K, r, T, blsprice(S0, K, r, T, σ, d) + 1000im, d)
end
