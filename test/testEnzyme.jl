using FinancialToolbox, Enzyme, ForwardDiff
using Test

S0 = 100.0;
K = 95.0;
r = 0.02;
T = 1.2;
σ = 0.25;
d = 0.01;

@test Base.get_extension(FinancialToolbox, :FinancialToolboxEnzymeCoreExt) !== nothing

for FlagIsCall in (true, false)
    price = blsprice(S0, K, r, T, σ, d, FlagIsCall)
    x = [S0, K, r, T, price, d]
    f(x) = @views blsimpv(x[1:1][], x[2:2][], x[3:3][], x[4:4][], x[5:5][], x[6:6][], FlagIsCall, 1e-12, 4)
    g_ref = ForwardDiff.gradient(f, x)

    # Gradient Rev and Fwd
    @test Enzyme.gradient(Enzyme.Reverse, f, x)[1] ≈ g_ref
    @test collect(Enzyme.gradient(Enzyme.Forward, f, x)[1]) ≈ g_ref

    # Mixed activity: only S0 and Price are differentiated
    f_partial(S0, Price) = blsimpv(S0, K, r, T, Price, d, FlagIsCall, 1e-12, 4)
    @test collect(Enzyme.autodiff(Enzyme.Reverse, f_partial, Active, Active(S0), Active(price))[1]) ≈ g_ref[[1, 5]]
    @test Enzyme.autodiff(Enzyme.Forward, f_partial, Duplicated(S0, 1.0), Const(price))[1] ≈ g_ref[1]
    # Batched forward mode with a constant argument
    @test collect(values(Enzyme.autodiff(Enzyme.Forward, f_partial, BatchDuplicated(S0, (1.0, 2.0)), Const(price))[1])) ≈ [g_ref[1], 2 * g_ref[1]]

    # blsprice is differentiated directly by Enzyme
    p(x) = @views blsprice(x[1:1][], x[2:2][], x[3:3][], x[4:4][], x[5:5][], x[6:6][], FlagIsCall)
    xp = [S0, K, r, T, σ, d]
    @test Enzyme.gradient(Enzyme.Reverse, p, xp)[1] ≈ ForwardDiff.gradient(p, xp)
end

# Jacobian of a strike strip (puts and calls): batched reverse mode, forward mode
strikes = (80.0, 100.0, 120.0)
flags = (false, true, true)
prices = [blsprice(S0, k, r, T, v, d, fl) for (k, v, fl) in zip(strikes, (0.3, 0.25, 0.22), flags)]
x_strip = [S0, r, T, d, prices...]
F_strip = let strikes = strikes, flags = flags
    x -> [blsimpv(x[1], strikes[i], x[2], x[3], x[4+i], x[4], flags[i], 1e-12, 4) for i = 1:3]
end
J_ref = ForwardDiff.jacobian(F_strip, x_strip)
@test Enzyme.jacobian(Enzyme.Reverse, F_strip, x_strip)[1] ≈ J_ref
@test Enzyme.jacobian(Enzyme.Reverse, F_strip, x_strip; chunk = Val(3))[1] ≈ J_ref
@test Enzyme.jacobian(Enzyme.Forward, F_strip, x_strip)[1] ≈ J_ref
