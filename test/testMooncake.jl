using FinancialToolbox, Mooncake
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

# Gradient
f(x) = blsimpv(x[1], x[2], x[3], x[4], x[5], x[6], true, 1e-6, 4)
backend = DI.AutoMooncake()
grad_cache = DI.prepare_gradient(f, backend, x)
g = DI.gradient(f, grad_cache, backend, x)
@show g