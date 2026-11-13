# Figures of the documentation, computed with the package at build time and saved as SVG in src/assets/figures, in a
# light and a dark variant: the stylesheet assets/figures.css shows the one of the theme of the reader.
using FinancialToolbox, ForwardDiff, Plots
using Plots.Colors: RGB, HSL
# GR draws without a display on the CI runner
ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")
gr()

const FIGURES = mkpath(joinpath(@__DIR__, "src", "assets", "figures"))

# Categorical slots in fixed order (validated for colour vision deficiencies on adjacent pairs, in both modes), and
# the ink of the text, of the axes and of the grid: the palette of the figures of FinancialFFT.jl.
const THEMES = (light = (series = ["#2563d9", "#0a8a6f", "#b86e0b", "#0b7fb3", "#2f8a3c", "#c2456e"], text = "#1f2328", muted = "#5b6470", axis = "#b9b4ab", grid = "#e6e3de", diverging = ["#2563d9", "#f7f6f3", "#c47a12"]), dark = (series = ["#4f8cff", "#00d4aa", "#ffb84d", "#38cfff", "#7ee787", "#ff6b9d"], text = "#f5f7fa", muted = "#a0aec0", axis = "#3a4466", grid = "#252d47", diverging = ["#4f8cff", "#151b2e", "#ffb84d"]))
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

# Newton basins of the complex implied volatility. For complex inputs blsimpv solves f(σ) = V with Newton's method in
# the complex plane, σ ← σ + (V - f(σ)) / ν(σ), started from the implied volatility of the real parts. Started instead
# from every σ₀ of the plane, the same iteration converges to one of the infinitely many complex roots: each point is
# coloured by its root (blue for the real implied volatility, 0.2), darker the more iterations it takes; points that
# do not converge in 100 iterations are left neutral. f is the undiscounted price (r = d = 0) of FinancialToolbox,
# without the domain checks of blsprice, which reject Re σ ≤ 0.
function newton_root(σ, S0, K, T, V)
    for n = 1:100
        Δ = (V - FinancialToolbox.blprice_impl(S0, K, T, σ, true)) / FinancialToolbox.blvega_impl(S0, K, T, σ)
        isfinite(Δ) || return σ, 0
        σ += Δ
        abs(Δ) <= 1e-12 * abs(σ) && return σ, n
    end
    return σ, 0
end

function newton_basins(xs, ys)
    S0, K, T, σ_real = 100.0, 120.0, 1.0, 0.2
    V = blsprice(S0, K, 0.0, T, σ_real, 0.0)
    return [newton_root(complex(x, y), S0, K, T, V) for y in ys, x in xs]
end

const BASIN_OVERVIEW = (range(-6.0, 6.0, length = 700), range(-6.0, 6.0, length = 700))
const BASIN_ZOOM = (range(1.5, 3.5, length = 700), range(1.5, 3.5, length = 700))
const BASINS = (newton_basins(BASIN_OVERVIEW...), newton_basins(BASIN_ZOOM...))

function basin_colour(theme, (σ, n))
    neutral = parse(RGB, theme.grid)
    (n == 0 || !isfinite(abs(σ))) && return neutral
    hue = abs(σ - 0.2) < 1e-6 ? 213.0 : mod(137.5 * round(Int, 4 * abs(σ)) + 30 * sign(imag(σ)), 360)
    return convert(RGB, HSL(hue, 0.7, clamp(0.68 - 0.03 * n, 0.12, 0.68)))
end

function fractal_figure(theme)
    panels = map(zip((BASIN_OVERVIEW, BASIN_ZOOM), BASINS, ("Starting points in [-6, 6]²", "Zoom on [1.5, 3.5]²"))) do ((xs, ys), basins, title)
        p = base_plot(theme; title = title, xlabel = "Re σ₀", ylabel = "Im σ₀", aspect_ratio = :equal, xlims = extrema(xs), ylims = extrema(ys), left_margin = 2Plots.mm, bottom_margin = 2Plots.mm)
        plot!(p, xs, ys, basin_colour.(Ref(theme), basins); yflip = false)
        return p
    end
    rectangle = Shape([1.5, 3.5, 3.5, 1.5], [1.5, 1.5, 3.5, 3.5])
    plot!(panels[1], rectangle; fillalpha = 0, linecolor = theme.text, linewidth = 1.5, label = nothing)
    return plot(panels...; layout = (1, 2), size = (900, 470), plot_title = "Newton basins of the complex implied volatility, S0 = 100, K = 120, T = 1, σ = 0.2", plot_titlefontsize = 12, plot_titlefontcolor = theme.text, background_color = :transparent)
end

# Derivatives of the implied volatility of a call with respect to each input, from ForwardDiff through blsimpv, against
# the strike. The price is the one of σ = 20%, so σ itself does not move. One panel per input, each with its own scale.
function implied_volatility_derivatives_figure(theme)
    S0 = 100.0
    strikes = collect(range(80.0, 200.0, length = 121))
    marked = 1:12:length(strikes)
    gradients = map(strikes) do strike
        V = blsprice(S0, strike, r, T, σ, d)
        ForwardDiff.gradient(y -> blsimpv(y...), [S0, strike, r, T, V, d])
    end
    panels = ["∂σ/∂S0" => 1, "∂σ/∂K" => 2, "∂σ/∂V" => 5, "∂σ/∂T" => 4, "∂σ/∂r" => 3, "∂σ/∂d" => 6]
    plots = map(enumerate(panels)) do (j, (name, i))
        values = getindex.(gradients, i)
        p = base_plot(theme; title = name, xlabel = j > 3 ? "strike" : "", legend = false, xlims = extrema(strikes), left_margin = 3Plots.mm, bottom_margin = 2Plots.mm)
        plot!(p, strikes, values; color = theme.series[j], linewidth = 2)
        scatter!(p, strikes[marked], values[marked]; color = theme.series[j], marker = MARKERS[j], markersize = 4, markerstrokewidth = 0)
        return p
    end
    return plot(plots...; layout = (2, 3), size = (900, 560), plot_title = "Derivatives of the implied volatility of a call, S0 = 100, σ = 20%, T = 1", plot_titlefontsize = 12, plot_titlefontcolor = theme.text, background_color = :transparent)
end

save_themes(greeks_figure, "greeks")
save_themes(accuracy_figure, "accuracy")
save_themes(fractal_figure, "fractal")
save_themes(implied_volatility_derivatives_figure, "impv_derivatives")
# The hero of the home page: the Newton basins of the complex implied volatility, the zoom of the fractal figure, alone.
function hero_figure(theme)
    (xs, ys), basins = BASIN_ZOOM, BASINS[2]
    p = plot(xs, ys, basin_colour.(Ref(theme), basins); size = (640, 640), background_color = :transparent, framestyle = :none, grid = false, legend = false, aspect_ratio = :equal, xlims = extrema(xs), ylims = extrema(ys), yflip = false, margin = 0Plots.mm)
    return p
end
save_themes(hero_figure, "hero-fractal")

using BenchmarkTools, Printf
"The key numbers of the home page, timed on the machine that builds the documentation."
function hero_stats()
    S0, K, r, T, σ, d = 100.0, 100.0, 0.02, 1.2, 0.2, 0.01
    price = blsprice(S0, K, r, T, σ, d)
    t_price = @belapsed blsprice($S0, $K, $r, $T, $σ, $d)
    t_impv = @belapsed blsimpv($S0, $K, $r, $T, $price, $d)
    tile(v, u, l; tone = "") = "<div class=\"fc-stat $tone\"><div class=\"fc-stat-value\">$v<span>$u</span></div><div class=\"fc-stat-label\">$l</div></div>"
    fmt(t) = t < 1e-6 ? @sprintf("%.0f", 1e9 * t) : @sprintf("%.2f", 1e6 * t)
    unit(t) = t < 1e-6 ? " ns" : " μs"
    tiles = [tile(fmt(t_price), unit(t_price), "one blsprice, on the machine that built this page"), tile(fmt(t_impv), unit(t_impv), "one blsimpv, at most two Householder steps"; tone = "is-teal"), tile("≤ 2", " steps", "Householder iterations of order four after the rational initial guess"; tone = "is-amber"), tile("9", "", "AD backends tested, plus Symbolics.jl")]
    return HTML("<div class=\"fc-stats\">" * join(tiles) * "</div>")
end
