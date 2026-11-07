# GPU code path on CI, without a GPU: JLArrays runs the broadcast kernels of GPUArrays on the CPU and forbids scalar
# indexing like a real device. The same tests run on CUDA with cuda/runtests.jl.
using JLArrays
include("gpu_suite.jl")
JLArrays.allowscalar(false)
@testset "GPU (JLArrays)" begin
    test_gpu(jl, (Float32, Float64))
end
