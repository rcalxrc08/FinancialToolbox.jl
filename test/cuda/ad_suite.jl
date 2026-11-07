# Automatic differentiation on CUDA, as in a calibration: the derivative of a loss over device data with respect to a
# shared parameter, and the gradient with respect to a device vector of prices. References are computed on the CPU.
using FinancialToolbox, CUDA, Test, ForwardDiff, DualNumbers, Zygote, Mooncake, Enzyme

function calibration_data(Tp, n)
    S0, r, T, d, σ = Tp(100), Tp(0.02), Tp(1.2), Tp(0.01), Tp(0.2)
    strikes = Tp.(collect(range(70, 140, length = n)))
    prices = blsprice.(S0, strikes, r, T, σ, d)
    return S0, r, T, d, σ, strikes, prices
end

# derivative of blsimpv with respect to the price, one thread per option (reverse mode with Enzyme)
function enzyme_price_kernel!(out, S0, K, r, T, σ, d)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    if i <= length(K)
        out[i] = Enzyme.autodiff_deferred(Enzyme.Reverse, Const(blsprice), Active, Const(S0), Const(K[i]), Const(r), Const(T), Active(σ), Const(d))[1][5]
    end
    return nothing
end
function enzyme_vega_kernel!(out, S0, K, r, T, σ, d)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    if i <= length(K)
        out[i] = Enzyme.autodiff_deferred(Enzyme.Forward, Const(blsprice), Duplicated, Const(S0), Const(K[i]), Const(r), Const(T), Duplicated(σ, one(σ)), Const(d))[1]
    end
    return nothing
end
function enzyme_impv_kernel!(out, S0, K, r, T, P, d)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    if i <= length(K)
        out[i] = Enzyme.autodiff_deferred(Enzyme.Reverse, Const(blsimpv), Active, Const(S0), Const(K[i]), Const(r), Const(T), Active(P[i]), Const(d))[1][5]
    end
    return nothing
end

function test_gpu_ad(element_types)
    n = 256
    for Tp in element_types
        rtol = Tp == Float32 ? 1e-3 : 1e-9
        S0, r, T, d, σ, strikes, prices = calibration_data(Tp, n)
        K, P = CuArray(strikes), CuArray(prices)
        # loss of a calibration of σ against market prices, and a loss of the implied volatilities
        loss_σ(s, K, P) = sum(abs2, blsprice.(S0, K, r, T, s, d) .- P .* Tp(1.01))
        loss_P(P, K) = sum(blsimpv.(S0, K, r, T, P, d))
        ref_σ = ForwardDiff.derivative(s -> loss_σ(s, strikes, prices), σ)
        ref_P = inv.(blsvega.(S0, strikes, r, T, σ, d))
        @testset "$Tp" begin
            @testset "ForwardDiff" begin
                @test ForwardDiff.derivative(s -> loss_σ(s, K, P), σ) ≈ ref_σ rtol = rtol
                # ForwardDiff.gradient does not support GPU arrays (JuliaDiff/ForwardDiff.jl#759): one dual per option
                dP = map((k, p) -> ForwardDiff.derivative(q -> blsimpv(S0, k, r, T, q, d), p), K, P)
                @test dP isa CuArray
                @test Array(dP) ≈ ref_P rtol = rtol
            end
            @testset "DualNumbers" begin
                # rtol: DualNumbers promotes erfc to Float64 (#74)
                @test DualNumbers.dualpart(loss_σ(DualNumbers.Dual(σ, one(σ)), K, P)) ≈ ref_σ rtol = rtol
            end
            @testset "Zygote" begin
                @test only(Zygote.gradient(s -> loss_σ(s, K, P), σ)) ≈ ref_σ rtol = rtol
                dP = only(Zygote.gradient(p -> loss_P(p, K), P))
                @test dP isa CuArray
                @test Array(dP) ≈ ref_P rtol = rtol
            end
            @testset "Mooncake" begin
                cache = Mooncake.prepare_gradient_cache(loss_σ, σ, K, P)
                @test Mooncake.value_and_gradient!!(cache, loss_σ, σ, K, P)[2][2] ≈ ref_σ rtol = rtol
                cache = Mooncake.prepare_gradient_cache(loss_P, P, K)
                dP = Mooncake.value_and_gradient!!(cache, loss_P, P, K)[2][2]
                @test dP isa CuArray
                @test Array(dP) ≈ ref_P rtol = rtol
            end
            @testset "Enzyme (in kernels)" begin
                out = CUDA.zeros(Tp, n)
                blocks = cld(n, 256)
                ref_vega = blsvega.(S0, strikes, r, T, σ, d)
                @cuda threads = 256 blocks = blocks enzyme_vega_kernel!(out, S0, K, r, T, σ, d)
                @test Array(out) ≈ ref_vega rtol = rtol
                @cuda threads = 256 blocks = blocks enzyme_price_kernel!(out, S0, K, r, T, σ, d)
                @test Array(out) ≈ ref_vega rtol = rtol
                # the rule of the implied volatility does not compile in kernels (EnzymeAD/Enzyme.jl#3962)
                @test_broken try
                    @cuda threads = 256 blocks = blocks enzyme_impv_kernel!(out, S0, K, r, T, P, d)
                    Array(out) ≈ ref_P
                catch
                    false
                end
            end
        end
    end
end
