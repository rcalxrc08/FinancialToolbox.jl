using Documenter, FinancialToolbox
# Documenter takes the logo and the favicon from the assets: etc/ holds the only copies, and git keeps no empty folder.
assets = mkpath(joinpath(@__DIR__, "src", "assets"))
for asset in ("logo.png", "favicon.ico")
    cp(joinpath(@__DIR__, "..", "etc", asset), joinpath(assets, asset), force = true)
end
# The figures are computed with the package, in a light and a dark variant (see figures.jl and assets/figures.css), in
# a module of their own.
module DocumentationFigures
include(joinpath(@__DIR__, "figures.jl"))
end
DocMeta.setdocmeta!(FinancialToolbox, :DocTestSetup, :(using FinancialToolbox); recursive = true)
makedocs(format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true", assets = ["assets/favicon.ico", "assets/figures.css", "assets/style.css", "assets/site.css", "assets/home.css", "assets/dark.js"], edit_link = "master"), repo = Remotes.GitHub("rcalxrc08", "FinancialToolbox.jl"), sitename = "FinancialToolbox.jl", modules = [FinancialToolbox], checkdocs = :exports, pages = ["Home" => "index.md", "Guides" => ["Pricing and Greeks" => "pricing.md", "Implied volatility" => "implied_volatility.md", "Automatic differentiation" => "ad.md", "GPU and calibration" => "gpu.md", "Performance" => "performance.md", "Dates" => "dates.md"], "Reference" => ["API" => "api.md", "References" => "references.md"]])
