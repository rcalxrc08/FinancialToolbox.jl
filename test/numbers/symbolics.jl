# Symbolics: blsprice and blsimpv of symbolic variables, first and second derivatives of the registered blimpv against
# HyperDualNumbers. The derivatives are not simplified: simplification is slow and the values are the same.
include(joinpath(@__DIR__, "..", "setup.jl"))
using Symbolics, HyperDualNumbers

# substitute the values and fold the result down to a plain number
substitute_value(ex, vals) = Symbolics.unwrap_const(Symbolics.unwrap(substitute(ex, vals; fold = Val(true))))

@variables S0_s, K_s, r_s, T_s, price_s, d_s, sigma_s

@testset "Symbolics" begin
    toll = 1e-7
    S0, K, r, T, σ, d = 100.0, 100.0, 0.02, 1.2, 0.2, 0.01
    price = blsprice(S0, K, r, T, σ, d)
    vals = Dict(S0_s => S0, K_s => K, r_s => r, T_s => T, price_s => price, d_s => d, sigma_s => σ)
    @test abs(substitute_value(blsprice(S0_s, K_s, r_s, T_s, sigma_s, d_s), vals) - price) < toll
    vol_s = blsimpv(S0_s, K_s, r_s, T_s, price_s, d_s)
    @test abs(substitute_value(vol_s, vals) - σ) < toll

    # first and second derivatives with respect to each input, against the epsilon1 and epsilon12 of a hyperdual input
    x = Any[S0, K, r, T, price, d]
    for (i, v) in ((1, S0_s), (2, K_s), (3, r_s), (4, T_s))
        y = copy(x)
        y[i] = hyper(y[i], 1.0, 1.0, 0.0)
        vol_h = blsimpv(y...)
        der1 = Symbolics.derivative(vol_s, v; simplify = false)
        @test abs(substitute_value(der1, vals) - vol_h.epsilon1) < toll
        @test abs(substitute_value(Symbolics.derivative(der1, v; simplify = false), vals) - vol_h.epsilon12) < toll
    end
    # mixed derivative in T and r
    vol_h = blsimpv(S0, K, hyper(r, 0.0, 1.0, 0.0), hyper(T, 1.0, 0.0, 0.0), price, d)
    mixed = Symbolics.derivative(Symbolics.derivative(vol_s, T_s; simplify = false), r_s; simplify = false)
    @test abs(substitute_value(mixed, vals) - vol_h.epsilon12) < toll

    # the derivatives with respect to FlagIsCall, xtol and n_iter_max are zero
    for i = 5:7
        @test isequal(Symbolics.unwrap_const(Symbolics.@derivative_rule(FinancialToolbox.blimpv(S0_s, K_s, T_s, price_s, true, 1e-14, 4), i)), 0)
    end
end
