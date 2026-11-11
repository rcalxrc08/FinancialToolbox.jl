# Every function keeps the element type of its inputs: Float32 in, Float32 out, also through the dual, hyperdual,
# Taylor and complex numbers of the extensions, for each input in turn. The code being type-stable, a promotion to a
# wider type is not caught by type-stability checks (see #74: DualNumbers promoted erfc and sqrt to Float64).
include(joinpath(@__DIR__, "..", "setup.jl"))
using ForwardDiff, DualNumbers, HyperDualNumbers, TaylorSeries

const S0_32, K_32, r_32, T_32, σ_32, d_32 = 100.0f0, 95.0f0, 0.02f0, 1.2f0, 0.2f0, 0.01f0
const PRICE_32 = blsprice(S0_32, K_32, r_32, T_32, σ_32, d_32)
const PRICING_FUNCTIONS = (blsprice, blsbin, blsdelta, blsgamma, blsvega, blsrho, blstheta, blslambda, blspsi, blsvanna)

# the Float32 at the base of each number type
base_value(y::ForwardDiff.Dual) = ForwardDiff.value(y)
base_value(y::DualNumbers.Dual) = DualNumbers.value(y)
base_value(y::HyperDualNumbers.Hyper) = HyperDualNumbers.value(y)
base_value(y::Taylor1) = y[0]
base_value(y::Complex) = real(y)
base_value(y) = y

lifts = (
    "Float32" => identity,
    "ForwardDiff" => x -> ForwardDiff.Dual(x, one(x)),
    "DualNumbers" => x -> DualNumbers.Dual(x, one(x)),
    "HyperDualNumbers" => x -> HyperDualNumbers.Hyper(x, one(x), one(x), zero(x)),
    "TaylorSeries" => x -> x + Taylor1(Float32, 3),
    # the imaginary part relative to the input, as for the complex step
    "Complex" => x -> complex(x, 1.0f-3 * x),
)

@testset "Element types" begin
    for (name, lift) in lifts
        @testset "$name" begin
            for i = 1:6
                args = Any[S0_32, K_32, r_32, T_32, σ_32, d_32]
                args[i] = lift(args[i])
                for f in PRICING_FUNCTIONS
                    @test base_value(f(args...)) isa Float32
                end
                args = Any[S0_32, K_32, r_32, T_32, PRICE_32, d_32]
                args[i] = lift(args[i])
                @test base_value(blsimpv(args...)) isa Float32
            end
            args = Any[S0_32, K_32, r_32, T_32, σ_32]
            args[5] = lift(args[5])
            @test base_value(blkprice(args...)) isa Float32
            @test base_value(normcdf(lift(0.3f0))) isa Float32
        end
    end
end

# Float16 mixed with integers: the inputs of the solver are promoted to Float16 (sqrt of an Int strike is a Float64),
# then solved in Float32 (erfinv is wrong for Float16, JuliaMath/SpecialFunctions.jl#571)
@testset "Float16 mixed with integers" begin
    for K in (100, 95, 110), FlagIsCall in (true, false)
        price = blsprice(Float16(100), K, Float16(0), Float16(1), Float16(0.2), Float16(0), FlagIsCall)
        σ = blsimpv(Float16(100), K, Float16(0), Float16(1), price, Float16(0), FlagIsCall)
        @test σ isa Float16
        @test σ ≈ 0.2 rtol = 2e-2
    end
end
