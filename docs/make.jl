using Documenter, FinancialToolbox

makedocs(format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
		assets = [asset("assets/favicon.ico", class = :ico, islocal = true),asset("assets/logo.png", class = :ico, islocal = true)]    ),
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