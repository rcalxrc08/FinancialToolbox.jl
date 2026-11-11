# The GPU tests on an NVIDIA GPU, with the AD backends, not run on CI (no GPU there):
#     julia --project=test/cuda -e 'import Pkg; Pkg.instantiate(); include("test/cuda/runtests.jl")'
using CUDA
include(joinpath(@__DIR__, "..", "gpu", "gpu_suite.jl"))
include(joinpath(@__DIR__, "ad_suite.jl"))
CUDA.functional() || error("CUDA is not functional on this machine")
CUDA.allowscalar(false)
@testset "GPU (CUDA, $(CUDA.name(CUDA.device())))" begin
    test_gpu(CuArray, (Float32, Float64))
    @testset "AD" begin
        test_gpu_ad((Float32, Float64))
    end
end
