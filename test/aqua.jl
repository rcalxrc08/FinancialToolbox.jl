# Quality checks of the package: method ambiguities, unbound type parameters, undefined exports, stale dependencies,
# compat bounds and type piracy. persistent_tasks is skipped: it starts another Julia process and is slow on CI.
using Aqua, FinancialToolbox, Test
@testset "Aqua" begin
    Aqua.test_all(FinancialToolbox; persistent_tasks = false)
end
