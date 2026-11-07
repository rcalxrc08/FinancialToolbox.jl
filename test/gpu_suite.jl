# Pricing, sensitivities and implied volatilities broadcast over GPU arrays, compared with the CPU. `to_device` moves
# a Vector to the device; scalar indexing must be disabled by the caller, so that every function runs inside the
# broadcast kernel. Run with JLArrays in testGPU.jl (CI) and with CUDA in cuda/runtests.jl.
using FinancialToolbox, Test

function test_gpu(to_device, element_types)
    sensitivities = (blsdelta, blsgamma, blsvega, blsrho, blstheta, blslambda, blspsi, blsvanna)
    for Tp in element_types
        # results of the device and of the CPU differ by the last bits of erfc, exp and log, amplified by 1 / vega
        # in the implied volatility
        rtol = 1000 * eps(Tp)
        n = 64
        S0, r, T, σ, d = Tp(100), Tp(0.02), Tp(1.2), Tp(0.2), Tp(0.01)
        strikes = Tp.(collect(range(70, 140, length = n)))
        K = to_device(strikes)
        S0_device = to_device(fill(S0, n))
        @testset "$Tp" begin
            for FlagIsCall in (true, false)
                price = blsprice.(S0_device, K, r, T, σ, d, FlagIsCall)
                @test !(price isa Array) # computed on the device
                @test Array(price) ≈ blsprice.(S0, strikes, r, T, σ, d, FlagIsCall) rtol = rtol
                @test Array(blsbin.(S0_device, K, r, T, σ, d, FlagIsCall)) ≈ blsbin.(S0, strikes, r, T, σ, d, FlagIsCall) rtol = rtol
                for f in sensitivities
                    @test Array(f.(S0_device, K, r, T, σ, d, FlagIsCall)) ≈ f.(S0, strikes, r, T, σ, d, FlagIsCall) rtol = rtol
                end
                @test Array(blsimpv.(S0_device, K, r, T, price, d, FlagIsCall)) ≈ fill(σ, n) rtol = rtol
                price_black = blkprice.(S0_device, K, r, T, σ, FlagIsCall)
                @test Array(price_black) ≈ blkprice.(S0, strikes, r, T, σ, FlagIsCall) rtol = rtol
                @test Array(blkimpv.(S0_device, K, r, T, price_black, FlagIsCall)) ≈ fill(σ, n) rtol = rtol
            end
            # scalars broadcast against a device array
            @test Array(blsprice.(S0, K, r, T, σ, d)) ≈ blsprice.(S0, strikes, r, T, σ, d) rtol = rtol
        end
    end
end
