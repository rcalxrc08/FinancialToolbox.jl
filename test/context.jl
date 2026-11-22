# The layered context (CLAUDE.md, CONTEXT.md, the stage contracts, references/, state/) must follow the code: every file
# a contract lists exists, every file the module includes and every reference is reached from a contract, every contract
# is routed from the root CONTEXT.md, and state/STATUS.md has its sections. A moved or added file without its contract
# fails here instead of leaving the map stale. Untracked experiments under src/ are not checked: only included files.
using Test

@testset "Context layers" begin
    root = normpath(joinpath(@__DIR__, ".."))
    rel(path) = replace(relpath(path, root), '\\' => '/')
    pkg = match(r"^name\s*=\s*\"([^\"]+)\""m, read(joinpath(root, "Project.toml"), String)).captures[1]
    folder_contracts = [joinpath(root, d, "CONTEXT.md") for d in ("ext", "test", "docs", "bench", "benchmark", "etc") if isdir(joinpath(root, d))]
    stage_contracts = [joinpath(root, "src", d, "CONTEXT.md") for d in readdir(joinpath(root, "src")) if isdir(joinpath(root, "src", d)) && occursin(r"^\d\d_", d)]
    contracts = vcat(folder_contracts, stage_contracts)
    routing = read(joinpath(root, "CONTEXT.md"), String)
    layer0 = read(joinpath(root, "CLAUDE.md"), String)
    listed = Set{String}()
    for contract in contracts
        @test isfile(contract) || error("$(rel(contract)) is missing")
        @test occursin("`$(rel(contract))`", routing) || error("$(rel(contract)) is not routed from CONTEXT.md")
        dir = dirname(contract)
        for line in eachline(contract)
            startswith(line, "| `") || continue
            first_cell = split(line, '|')[2]
            for m in eachmatch(r"`([^`*<>]+\.(?:jl|md))`", first_cell)
                name = m.captures[1]
                path = isfile(joinpath(dir, name)) ? joinpath(dir, name) : joinpath(root, name)
                @test isfile(path) || error("$(rel(contract)) lists $name, which does not exist")
                push!(listed, rel(path))
            end
        end
    end
    # Every file the module includes, recursively through the stage files, belongs to a contract.
    function included(file)
        out = String[]
        for m in eachmatch(r"^\s*include\(\"([^\"]+)\"\)"m, read(file, String))
            path = normpath(joinpath(dirname(file), m.captures[1]))
            push!(out, rel(path))
            isfile(path) && append!(out, included(path))
        end
        return out
    end
    for path in included(joinpath(root, "src", "$pkg.jl"))
        @test path in listed || error("$path is in no stage contract")
    end
    for file in readdir(joinpath(root, "references"))
        path = "references/$file"
        @test path in listed || occursin(path, layer0) || occursin(file, routing) || error("$path is reached from no contract, nor CONTEXT.md, nor CLAUDE.md")
    end
    status = joinpath(root, "state", "STATUS.md")
    @test isfile(status) || error("state/STATUS.md is missing")
    text = read(status, String)
    for section in ("## Current focus", "## Active work", "## Known issues")
        @test occursin(section, text) || error("state/STATUS.md has no '$section' section")
    end
    @test occursin(r"Updated: \d{4}-\d{2}-\d{2}", text) || error("state/STATUS.md has no 'Updated: YYYY-MM-DD' date")
end
