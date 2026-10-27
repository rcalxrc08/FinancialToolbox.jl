using FinancialToolbox, Mooncake, ForwardDiff, ChainRulesCore
import DifferentiationInterface as DI
using Test

S0 = 100.0;
K = 100.0;
r = 0.02;
T = 1.0;
σ = 0.2;
d = 0.01;
price = blsprice(S0, K, r, T, σ, d);
const x = [S0, K, r, T, price, d]

@assert Mooncake.is_primitive(
    Mooncake.DefaultCtx,
    Mooncake.ReverseMode,
    Tuple{typeof(FinancialToolbox.blimpv),Float64,Float64,Float64,Float64,Bool,Float64,Int},
    Base.get_world_counter(),
)

for FlagIsCall in (true, false)
    x_flag = [S0, K, r, T, blsprice(S0, K, r, T, σ, d, FlagIsCall), d]
    f(x) = @views blsimpv(x[1:1][], x[2:2][], x[3:3][], x[4:4][], x[5:5][], x[6:6][], FlagIsCall, 1e-12, 4)
    g_ref = ForwardDiff.gradient(f, x_flag)
    # Gradient Rev
    backend = DI.AutoMooncake()
    grad_cache = DI.prepare_gradient(f, backend, x_flag)
    @test DI.gradient(f, grad_cache, backend, x_flag) ≈ g_ref
    # Gradient Fwd (rules derived from the ChainRulesCore frule)
    backend_fwd = DI.AutoMooncakeForward()
    grad_cache_fwd = DI.prepare_gradient(f, backend_fwd, x_flag)
    @test DI.gradient(f, grad_cache_fwd, backend_fwd, x_flag) ≈ g_ref
end

# ChainRulesCore rules of blimpv: derivatives are -(∂Price/∂θ) / vega and 1 / vega w.r.t. the price
σ_cr, pullback = ChainRulesCore.rrule(FinancialToolbox.blimpv, S0, K, T, price, true, 1e-12, 4)
_, dS0, dK, dT, dprice = pullback(1.0)
σ_fr, dσ = ChainRulesCore.frule((NoTangent(), 1.0, 2.0, 3.0, 4.0, NoTangent(), NoTangent(), NoTangent()), FinancialToolbox.blimpv, S0, K, T, price, true, 1e-12, 4)
@test σ_cr == σ_fr
@test dprice ≈ 1 / FinancialToolbox.blvega_impl(S0, K, T, σ_cr)
@test dσ ≈ dS0 + 2 * dK + 3 * dT + 4 * dprice

# hess_backend_1 = DI.SecondOrder(DI.AutoMooncakeForward(), DI.AutoMooncake())
# hess_cache_1 = DI.prepare_hessian(f, hess_backend_1, x)
# H1 = DI.hessian(f, hess_cache_1, hess_backend_1, x)
# @show H1

# hess_backend_2 = DI.SecondOrder(DI.AutoMooncake(), DI.AutoMooncakeForward())
# hess_cache_2 = DI.prepare_hessian(f, hess_backend_2, x)
# H2 = DI.hessian(f, hess_cache_2, hess_backend_2, x)
# @show H2