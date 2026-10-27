# Environment for running the suite locally: the dependencies of benchmark/Project.toml and the package in this
# repository, in a temporary environment (on CI BenchmarkCI does the same)
using Pkg
let env = mktempdir()
    cp(joinpath(@__DIR__, "Project.toml"), joinpath(env, "Project.toml"))
    Pkg.activate(env; io = devnull)
    Pkg.develop(PackageSpec(path = dirname(@__DIR__)); io = devnull)
    Pkg.instantiate(; io = devnull)
end
