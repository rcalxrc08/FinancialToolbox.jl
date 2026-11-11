# Forward mode number types: ForwardDiff, DualNumbers and HyperDualNumbers. First derivatives against the closed
# form sensitivities, the implied volatility (solved on the values, derivatives by the implicit function theorem),
# second derivatives with HyperDualNumbers.
include(joinpath(@__DIR__, "..", "setup.jl"))
using ForwardDiff, DualNumbers, HyperDualNumbers

# name => (x -> number seeded with dx = 1, first derivative, value)
const FORWARD_TYPES = (
    "ForwardDiff" => (x -> ForwardDiff.Dual(x, one(x)), y -> ForwardDiff.partials(y)[1], ForwardDiff.value),
    "DualNumbers" => (x -> DualNumbers.Dual(x, one(x)), DualNumbers.epsilon, DualNumbers.value),
    "HyperDualNumbers" => (x -> HyperDualNumbers.Hyper(x, one(x), one(x), zero(x)), y -> y.epsilon1, y -> y.value),
)

@testset "$name" for (name, (seed, derivative, value)) in FORWARD_TYPES
    (; S0, K, r, T, σ, d) = REFERENCE
    toll = 1e-13
    for FlagIsCall in (true, false)
        g = closed_form_greeks(FlagIsCall)
        @test abs(derivative(blsprice(seed(S0), K, r, T, σ, d, FlagIsCall)) - g.delta) < toll
        @test abs(derivative(blsprice(S0, K, seed(r), T, σ, d, FlagIsCall)) - g.rho) < toll
        @test abs(-derivative(blsprice(S0, K, r, seed(T), σ, d, FlagIsCall)) - g.theta) < toll
        @test abs(derivative(blsprice(S0, K, r, T, seed(σ), d, FlagIsCall)) - g.vega) < toll
        @test abs(derivative(blsprice(S0, K, r, T, σ, seed(d), FlagIsCall)) - g.psi) < toll
        @test abs(derivative(blsdelta(S0, K, r, T, seed(σ), d, FlagIsCall)) - g.vanna) < toll
        # implied volatility: of a price with the same dependence on S0, σ is constant; dσ/dprice = 1 / vega
        vol = blsimpv(seed(S0), K, r, T, blsprice(seed(S0), K, r, T, σ, d, FlagIsCall), d, FlagIsCall)
        @test abs(value(vol) - σ) < toll
        @test abs(derivative(vol)) < toll
        vol = blsimpv(seed(S0), K, r, T, blsprice(seed(S0), K, r, T, seed(σ), d, FlagIsCall), d, FlagIsCall)
        @test abs(derivative(vol) - 1) < toll
        @test abs(derivative(blsimpv(S0, K, r, T, seed(g.price), d, FlagIsCall)) - 1 / g.vega) < toll
        vol = blkimpv(seed(S0), K, r, T, blkprice(seed(S0), K, r, T, σ, FlagIsCall), FlagIsCall)
        @test abs(value(vol) - σ) < toll
        @test abs(derivative(vol)) < toll
    end
    # input validation is generic code: one check per input
    x = Any[S0, K, r, T, σ, d]
    for i in (1, 2, 4, 5)
        y = copy(x)
        y[i] = -seed(y[i])
        @test_throws DomainError blsprice(y...)
    end
    @test_throws DomainError blsimpv(seed(S0), K, r, T, -0.2, d)
end

@testset "HyperDualNumbers: second order" begin
    (; S0, K, r, T, σ, d) = REFERENCE
    toll = 1e-13
    S0_h = hyper(S0, 1.0, 1.0, 0.0)
    K_h = hyper(K, 1.0, 1.0, 0.0)
    σ_h = hyper(σ, 1.0, 2.0, 3.0)
    for FlagIsCall in (true, false)
        g = closed_form_greeks(FlagIsCall)
        @test abs(blsprice(S0_h, K, r, T, σ, d, FlagIsCall).epsilon12 - g.gamma) < toll
        @test abs(blsprice(hyper(S0, 1.0, 0.0, 0.0), K, r, T, hyper(σ, 0.0, 1.0, 0.0), d, FlagIsCall).epsilon12 - g.vanna) < toll
        # the implied volatility recovers σ to the second order
        vol = blsimpv(S0_h, K, r, T, blsprice(S0_h, K, r, T, σ, d, FlagIsCall), d, FlagIsCall)
        @test abs(vol.value - σ) < toll
        @test abs(vol.epsilon1) < toll
        @test abs(vol.epsilon12) < toll
        vol = blsimpv(S0_h, K_h, r, T, blsprice(S0_h, K_h, r, T, σ_h, d, FlagIsCall), d, FlagIsCall)
        @test abs(vol.value - σ_h.value) < toll
        @test abs(vol.epsilon1 - σ_h.epsilon1) < toll
        @test abs(vol.epsilon2 - σ_h.epsilon2) < toll
        @test abs(vol.epsilon12 - σ_h.epsilon12) < toll
    end
end
