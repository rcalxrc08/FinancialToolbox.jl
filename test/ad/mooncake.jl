# Mooncake, reverse and forward mode through DifferentiationInterface: blprice_impl and blimpv are primitives (their
# ChainRulesCore rules), checked against ForwardDiff. The NDual of Mooncake (GPU broadcasts) is called directly.
include(joinpath(@__DIR__, "..", "setup.jl"))
using Mooncake, ForwardDiff, ChainRulesCore
import DifferentiationInterface as DI

const S0, K, r, T, σ, d = 100.0, 100.0, 0.02, 1.0, 0.2, 0.01

for sig in (Tuple{typeof(FinancialToolbox.blimpv),Float64,Float64,Float64,Float64,Bool,Float64,Int}, Tuple{typeof(FinancialToolbox.blprice_impl),Float64,Float64,Float64,Float64,Bool})
    @test Mooncake.is_primitive(Mooncake.DefaultCtx, Mooncake.ReverseMode, sig, Base.get_world_counter())
end

@testset "Gradients" begin
    x = [S0, K, r, T, σ, d]
    for FlagIsCall in (true, false)
        # scalars read from views: Mooncake differentiates with respect to the vector
        impv(x) = @views blsimpv(x[1:1][], x[2:2][], x[3:3][], x[4:4][], x[5:5][], x[6:6][], FlagIsCall, 1e-12, 4)
        price(x) = @views blsprice(x[1:1][], x[2:2][], x[3:3][], x[4:4][], x[5:5][], x[6:6][], FlagIsCall)
        black(x) = @views blkprice(x[1:1][], x[2:2][], x[3:3][], x[4:4][], x[5:5][], FlagIsCall)
        x_impv = [x[1:4]; blsprice(x..., FlagIsCall); d]
        for (f, x0) in ((impv, x_impv), (price, x), (black, x[1:5]))
            g_ref = ForwardDiff.gradient(f, x0)
            for backend in (DI.AutoMooncake(), DI.AutoMooncakeForward())
                @test DI.gradient(f, DI.prepare_gradient(f, backend, x0), backend, x0) ≈ g_ref
            end
        end
    end
end

# ChainRulesCore rules of blimpv: the derivatives are -(∂price/∂θ) / vega, and 1 / vega with respect to the price
@testset "ChainRulesCore rules of blimpv" begin
    price = blsprice(S0, K, r, T, σ, d)
    σ_rr, pullback = ChainRulesCore.rrule(FinancialToolbox.blimpv, S0, K, T, price, true, 1e-12, 4)
    _, dS0, dK, dT, dprice = pullback(1.0)
    σ_fr, dσ = ChainRulesCore.frule((NoTangent(), 1.0, 2.0, 3.0, 4.0, NoTangent(), NoTangent(), NoTangent()), FinancialToolbox.blimpv, S0, K, T, price, true, 1e-12, 4)
    @test σ_rr == σ_fr
    @test dprice ≈ 1 / FinancialToolbox.blvega_impl(S0, K, T, σ_rr)
    @test dσ ≈ dS0 + 2 * dK + 3 * dT + 4 * dprice
end

# Mooncake differentiates GPU broadcasts with its own dual numbers (Nfwd.NDual): the extension solves on the values and
# adds the derivatives. Called directly here, on the CPU.
if isdefined(Mooncake, :Nfwd) && isdefined(Mooncake.Nfwd, :NDual)
    @testset "Mooncake NDual" begin
        K = 95.0
        price = blsprice(S0, K, r, T, σ, d)
        vega = blsvega(S0, K, r, T, σ, d)
        y = blsimpv(S0, K, r, T, Mooncake.Nfwd.NDual{Float64,2}(price, (1.0, 2.0)), d)
        @test y.value ≈ σ
        @test y.partials[1] ≈ inv(vega)
        @test y.partials[2] ≈ 2 * inv(vega)
        y = blsimpv(Mooncake.Nfwd.NDual{Float64,1}(S0, (1.0,)), K, r, T, price, d)
        @test y.partials[1] ≈ ForwardDiff.derivative(s -> blsimpv(s, K, r, T, price, d), S0)
    end
end
