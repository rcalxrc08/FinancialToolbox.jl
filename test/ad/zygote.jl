# Zygote: gradients with respect to all the inputs, through the ChainRules rules of blprice_impl and blimpv, against
# ForwardDiff; the frule of blprice_impl.
include(joinpath(@__DIR__, "..", "setup.jl"))
using Zygote, ForwardDiff, ChainRulesCore

@testset "Zygote" begin
    x = [100.0, 95.0, 0.02, 1.5, 0.25, 0.01]
    for FlagIsCall in (true, false)
        x_impv = [x[1:4]; blsprice(x..., FlagIsCall); x[6]]
        x_black = [x[1:4]; blkprice(x[1:5]..., FlagIsCall)]
        for (f, y) in ((blsprice, x), (blkprice, x[1:5]), (blsimpv, x_impv), (blkimpv, x_black))
            @test collect(Zygote.gradient((z...) -> f(z..., FlagIsCall), y...)) ≈ ForwardDiff.gradient(z -> f(z..., FlagIsCall), y)
        end
        # frule: directional derivative along (1, 2, 3, 4) of (S0, K, T, σ)
        S0, K, T, σ = 100.0, 95.0, 1.5, 0.25
        p, dp = ChainRulesCore.frule((NoTangent(), 1.0, 2.0, 3.0, 4.0, NoTangent()), FinancialToolbox.blprice_impl, S0, K, T, σ, FlagIsCall)
        @test p ≈ FinancialToolbox.blprice_impl(S0, K, T, σ, FlagIsCall)
        @test dp ≈ ForwardDiff.derivative(h -> FinancialToolbox.blprice_impl(S0 + h, K + 2h, T + 3h, σ + 4h, FlagIsCall), 0.0)
    end
end
