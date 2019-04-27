using Documenter, FinancialToolbox

makedocs(format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
		assets = ["assets/favicon.ico"]
		assets = ["assets/logo.png"]
    ),
	sitename="FinancialToolbox.jl",
	modules = [FinancialToolbox],
		pages = [
				"index.md",
				"starting.md",
				"dates.md",
				"bls.md"
			])
get(ENV, "CI", nothing) == "true" ? deploydocs(
    repo = "github.com/rcalxrc08/FinancialToolbox.jl.git",
) : nothing;