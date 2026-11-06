# Figures of the documentation, computed with the package at build time and saved as SVG in src/assets/figures, in a
# light and a dark variant: the stylesheet assets/figures.css shows the one of the theme of the reader.
using FinancialToolbox, Plots
# GR draws without a display on the CI runner
ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")
gr()

const FIGURES = mkpath(joinpath(@__DIR__, "src", "assets", "figures"))

# Categorical slots in fixed order (validated for colour vision deficiencies on adjacent pairs, in both modes), and
# the ink of the text, of the axes and of the grid: the palette of the figures of FinancialFFT.jl.
const THEMES = (light = (series = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300"], text = "#1f2328", muted = "#5b6470", axis = "#b9b4ab", grid = "#e6e3de"), dark = (series = ["#3987e5", "#d95926", "#199e70", "#c98500", "#d55181", "#008300"], text = "#e6e8eb", muted = "#9aa3ad", axis = "#4a525c", grid = "#2a2f36"))
# The secondary encoding of the series: the light slots 3-5 are below 3:1 contrast on the surface.
const MARKERS = [:circle, :rect, :utriangle, :diamond, :dtriangle, :star5]

function base_plot(theme; kwargs...)
    return plot(; size = (760, 430), background_color = :transparent, foreground_color_text = theme.muted, foreground_color_guide = theme.muted, foreground_color_axis = theme.axis, foreground_color_border = theme.axis, foreground_color_legend = nothing, legend_background_color = :transparent, legendfontcolor = theme.text, titlefontcolor = theme.text, gridcolor = theme.grid, gridalpha = 1, gridlinewidth = 1, framestyle = :axes, fontfamily = "sans-serif", titlefontsize = 12, guidefontsize = 10, tickfontsize = 9, legendfontsize = 9, titlelocation = :left, left_margin = 4Plots.mm, bottom_margin = 4Plots.mm, kwargs...)
end

function save_themes(draw, name)
    for (theme_name, theme) in pairs(THEMES)
        savefig(draw(theme), joinpath(FIGURES, "$name-$theme_name.svg"))
    end
end

const K, r, T, σ, d = 100.0, 0.02, 1.0, 0.2, 0.01

# Price and Greeks of a call and a put as functions of the spot, one panel each. Gamma and vega do not depend on the
# type of the option: one curve.
function greeks_figure(theme)
    spots = collect(range(50.0, 150.0, length = 201))
    marked = 1:25:length(spots)
    panels = ["Price" => blsprice, "Delta" => blsdelta, "Gamma" => blsgamma, "Vega" => blsvega]
    plots = map(enumerate(panels)) do (i, (name, f))
        p = base_plot(theme; title = name, xlabel = i > 2 ? "spot" : "", legend = i == 1 ? :topleft : false, left_margin = 2Plots.mm, bottom_margin = 2Plots.mm)
        options = name in ("Gamma", "Vega") ? ["call and put" => true] : ["call" => true, "put" => false]
        for (j, (label, iscall)) in enumerate(options)
            values = f.(spots, K, r, T, σ, d, iscall)
            plot!(p, spots, values; label = nothing, color = theme.series[j], linewidth = 2)
            scatter!(p, spots[marked], values[marked]; label = label, color = theme.series[j], marker = MARKERS[j], markersize = 5, markerstrokewidth = 0)
        end
        return p
    end
    return plot(plots...; layout = (2, 2), size = (900, 620), plot_title = "European options, K = 100, r = 2%, d = 1%, T = 1, σ = 20%", plot_titlefontsize = 12, plot_titlefontcolor = theme.text, background_color = :transparent)
end

# Accuracy of blsimpv in Float64: the distance from the implied volatility of the same Float64 price computed in
# BigFloat, in units of eps(Float64), for out of the money options across moneyness and volatilities. Prices that
# underflow (deep out of the money, low volatility) have no implied volatility and are left out.
function accuracy_figure(theme)
    setprecision(BigFloat, 256) do
        S0 = 100.0
        x = range(-4.0, 4.0, length = 161)
        p = base_plot(theme; title = "Error of blsimpv in Float64 against BigFloat, T = 1, out of the money options", xlabel = "log-moneyness log(S0 / K)", ylabel = "|σ̂ - σ| / σ, in eps(Float64)", legend = :outerright, size = (900, 430), ylims = (0, 4))
        for (j, vol) in enumerate((0.05, 0.2, 0.5, 1.0, 2.0))
            xs, errors = Float64[], Float64[]
            for xi in x
                strike = S0 * exp(-xi)
                iscall = xi < 0
                price = blsprice(S0, strike, 0.0, 1.0, vol, 0.0, iscall)
                price > floatmin(Float64) || continue
                σ_float = blsimpv(S0, strike, 0.0, 1.0, price, 0.0, iscall)
                σ_big = blsimpv(big(S0), big(strike), big(0.0), big(1.0), big(price), big(0.0), iscall)
                push!(xs, xi)
                push!(errors, Float64(abs(σ_float - σ_big) / σ_big) / eps(Float64))
            end
            scatter!(p, xs, errors; label = "σ = $vol", color = theme.series[j], marker = MARKERS[j], markersize = 4, markerstrokewidth = 0)
        end
        return p
    end
end

save_themes(greeks_figure, "greeks")
save_themes(accuracy_figure, "accuracy")
