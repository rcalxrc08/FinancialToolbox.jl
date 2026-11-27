# Prices, Greeks and their gradients compiled by Reactant (XLA), against plain Julia. Not run on CI (Reactant takes
# minutes to precompile); run it locally after a change to src/02_pricing, src/03_barriers or the Reactant extension:
#     julia --project=test/reactant -e 'import Pkg; Pkg.instantiate(); include("test/reactant/runtests.jl")'
# The XLA backend comes from the environment variable REACTANT_BACKEND ("cpu" by default, "cuda" on Linux with a GPU).
using Test, Reactant, Enzyme, FinancialToolbox

const BACKEND = get(ENV, "REACTANT_BACKEND", "cpu")
Reactant.set_default_backend(BACKEND)

# Every function in the trace is a named function: @jit of a closure defined at top level does not compile it again.
const S0, r, d, H_down, H_up = 100.0, 0.02, 0.01, 80.0, 130.0
call_price(K, T, σ) = blsprice(S0, K, r, T, σ, d)
put_price(K, T, σ) = blsprice(S0, K, r, T, σ, d, false)
black_price(K, T, σ) = blkprice(S0, K, r, T, σ)
binary(K, T, σ) = blsbin(S0, K, r, T, σ, d)
delta(K, T, σ) = blsdelta(S0, K, r, T, σ, d)
gamma(K, T, σ) = blsgamma(S0, K, r, T, σ, d)
vega(K, T, σ) = blsvega(S0, K, r, T, σ, d)
theta(K, T, σ) = blstheta(S0, K, r, T, σ, d)
rho(K, T, σ) = blsrho(S0, K, r, T, σ, d)
lambda(K, T, σ) = blslambda(S0, K, r, T, σ, d)
psi(K, T, σ) = blspsi(S0, K, r, T, σ, d)
vanna(K, T, σ) = blsvanna(S0, K, r, T, σ, d)
down_out(K, T, σ) = blsdownout(S0, K, r, T, σ, d, H_down)
up_in_put(K, T, σ) = blsupin(S0, K, r, T, σ, d, H_up, false)
const FUNCTIONS = (call_price, put_price, black_price, binary, delta, gamma, vega, theta, rho, lambda, psi, vanna, down_out, up_in_put)
# On Windows the XLA CPU JIT cannot link the barrier prices (Reactant 0.2.309: "Symbols not found: [ ___chkstk_ms ]",
# the stack probe of a large fused kernel); they compile on Linux, CPU and CUDA.
const WINDOWS_BROKEN = (down_out, up_in_put)

call_price_32(K, T, σ) = blsprice(100.0f0, K, 0.02f0, T, σ, 0.01f0)

traced_broadcast(f, K, T, σ) = f.(K, T, σ)
sum_of_prices(σ, K, T) = sum(call_price.(K, T, σ))
implied_vol(K, T, price) = blsimpv(S0, K, r, T, price, d)
traced_implied_vol(K, T, price) = implied_vol.(K, T, price)

@testset "Reactant ($BACKEND)" begin
    n = 101
    K = collect(range(60.0, 160.0; length = n))
    T = collect(range(0.1, 3.0; length = n))
    σ = collect(range(0.1, 0.5; length = n))
    Kr, Tr, σr = Reactant.to_rarray.((K, T, σ))
    @testset "$f" for f in FUNCTIONS
        expected = f.(K, T, σ)
        if Sys.iswindows() && f in WINDOWS_BROKEN
            @test_broken try
                Array(@jit(traced_broadcast(f, Kr, Tr, σr))) ≈ expected
            catch
                false
            end
        else
            @test Array(@jit(traced_broadcast(f, Kr, Tr, σr))) ≈ expected rtol = 1e-12 atol = 1e-12
        end
    end
    @testset "Float32" begin
        K32, T32, σ32 = Float32.(K), Float32.(T), Float32.(σ)
        out = Array(@jit(traced_broadcast(call_price_32, Reactant.to_rarray.((K32, T32, σ32))...)))
        @test eltype(out) == Float32
        @test out ≈ call_price.(K, T, σ) rtol = 1e-4
    end
    @testset "Enzyme reverse and forward mode" begin
        @test Array(@jit(Enzyme.gradient(Reverse, sum_of_prices, σr, Const(Kr), Const(Tr)))[1]) ≈ vega.(K, T, σ) rtol = 1e-12
        tangent = Reactant.to_rarray(ones(n))
        @test only(@jit(Enzyme.autodiff(Forward, sum_of_prices, Duplicated(σr, tangent), Const(Kr), Const(Tr)))) ≈ sum(vega.(K, T, σ)) rtol = 1e-12
    end
    # Let's Be Rational branches on values (its regions and its Householder loops): XLA cannot compile it yet (#92)
    @testset "blsimpv" begin
        price = Reactant.to_rarray(call_price.(K, T, σ))
        @test_broken try
            Array(@jit(traced_implied_vol(Kr, Tr, price))) ≈ σ
        catch
            false
        end
    end
end
