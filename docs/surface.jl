# A surface z(x, y) in perspective, as an SVG of its own: the hero figure of the home pages of the rcalxrc08 packages
# (the same file in every repository). Quads coloured by height along the ramp of the site and shaded by their normal,
# drawn from the farthest (painter's algorithm), with optional points (filled or hollow) sorted among them, a floor grid
# and three labelled axes. Plain Julia and Printf: no plotting package.
using Printf

const SURFACE_THEMES = (dark = (ramp = ["#22346b", "#4f8cff", "#38cfff", "#00d4aa", "#7ee787", "#ffb84d"], marker = "#ffb84d", ring = "#0b1020", text = "#f5f7fa", muted = "#a0aec0", axis = "#3a4466", grid = "#252d47", floor = "#151b2e"), light = (ramp = ["#c7d6f5", "#4f8cff", "#1ea6d4", "#00a585", "#4db55c", "#e8962a"], marker = "#b86e0b", ring = "#ffffff", text = "#1f2328", muted = "#5b6470", axis = "#b9b4ab", grid = "#e6e3de", floor = "#f3f1ec"))

surface_hex(h) = (parse(Int, h[2:3]; base = 16), parse(Int, h[4:5]; base = 16), parse(Int, h[6:7]; base = 16))
surface_rgb(c) = "#" * join(string(round(Int, clamp(x, 0, 255)); base = 16, pad = 2) for x in c)
surface_mix(a, b, w) = surface_rgb((1 - w) .* surface_hex(a) .+ w .* surface_hex(b))
function surface_ramp(stops, u)
    u = clamp(u, 0, 1) * (length(stops) - 1)
    i = min(floor(Int, u), length(stops) - 2)
    return surface_mix(stops[i+1], stops[i+2], u - i)
end

"""
    surface_svg(theme, xs, ys, Z; zlims, xticks, yticks, zticks, xlabel, ylabel, zlabel, points = (), label)

`Z[i, j]` is the height at `(xs[j], ys[i])`; NaN leaves a hole. Ticks are vectors of `value => text` in the units of
the axes; `points` are `(x, y, z, filled)`. `theme` is `:dark` or `:light`.
"""
function surface_svg(theme::Symbol, xs, ys, Z; zlims = extrema(filter(isfinite, Z)), xticks = [], yticks = [], zticks = [], xlabel = "", ylabel = "", zlabel = "", points = (), label = "surface", height = 0.8, azimuth = -38, elevation = 24)
    v = SURFACE_THEMES[theme]
    zlo, zhi = zlims
    X(x) = (x - first(xs)) / (last(xs) - first(xs)) - 0.5
    Y(y) = (y - first(ys)) / (last(ys) - first(ys)) - 0.5
    H(z) = height * (z - zlo) / (zhi - zlo)
    az, el = deg2rad(azimuth), deg2rad(elevation)
    W, Hpx, scale, cx, cy = 960, 640, 600, 470, 440
    function project(x, y, z)
        xr = x * cos(az) - y * sin(az)
        yr = x * sin(az) + y * cos(az)
        return (cx + scale * xr, cy - scale * (z * cos(el) + yr * sin(el)), yr * cos(el) - z * sin(el))
    end
    f(x) = @sprintf("%.1f", x)
    pt(p) = f(p[1]) * "," * f(p[2])
    items = Tuple{Float64, String}[]
    light = [-0.35, -0.55, 0.75] ./ sqrt(0.35^2 + 0.55^2 + 0.75^2)
    for i = 1:(length(ys)-1), j = 1:(length(xs)-1)
        z4 = (Z[i, j], Z[i, j+1], Z[i+1, j+1], Z[i+1, j])
        all(isfinite, z4) || continue
        c = [(X(xs[j]), Y(ys[i]), H(z4[1])), (X(xs[j+1]), Y(ys[i]), H(z4[2])), (X(xs[j+1]), Y(ys[i+1]), H(z4[3])), (X(xs[j]), Y(ys[i+1]), H(z4[4]))]
        p = [project(q...) for q in c]
        a, b = c[3] .- c[1], c[4] .- c[2]
        n = (a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1])
        n = n ./ sqrt(sum(abs2, n))
        fill = surface_mix(v.floor, surface_ramp(v.ramp, (sum(z4) / 4 - zlo) / (zhi - zlo)), 0.72 + 0.28 * abs(sum(n .* light)))
        push!(items, (sum(q[3] for q in p) / 4, "<polygon points=\"$(join(pt.(p), " "))\" fill=\"$fill\" stroke=\"$(surface_mix(fill, v.text, 0.18))\" stroke-width=\"0.6\" stroke-opacity=\"0.55\"/>"))
    end
    for (x, y, z, filled) in points
        p = project(X(x), Y(y), H(z))
        dot = filled ? "<circle cx=\"$(f(p[1]))\" cy=\"$(f(p[2]))\" r=\"5\" fill=\"$(v.marker)\" stroke=\"$(v.ring)\" stroke-width=\"1.8\"/>" : "<circle cx=\"$(f(p[1]))\" cy=\"$(f(p[2]))\" r=\"4.4\" fill=\"none\" stroke=\"$(v.marker)\" stroke-width=\"1.6\"/>"
        push!(items, (p[3] - 1e-3, dot))
    end
    sort!(items; by = first, rev = true)
    line(a, b; color = v.grid) = "<line x1=\"$(f(a[1]))\" y1=\"$(f(a[2]))\" x2=\"$(f(b[1]))\" y2=\"$(f(b[2]))\" stroke=\"$color\" stroke-width=\"1\"/>"
    text(p, s; anchor = "middle", size = 17) = "<text x=\"$(f(p[1]))\" y=\"$(f(p[2]))\" fill=\"$(v.muted)\" font-size=\"$size\" text-anchor=\"$anchor\">$s</text>"
    io = IOBuffer()
    print(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 $W $Hpx\" font-family=\"system-ui, -apple-system, Segoe UI, Roboto, sans-serif\" role=\"img\" aria-label=\"$label\">")
    zf = H(zlo)
    corners = [project(x, y, zf) for (x, y) in ((-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5))]
    print(io, "<polygon points=\"$(join(pt.(corners), " "))\" fill=\"$(v.floor)\" fill-opacity=\"0.55\" stroke=\"$(v.axis)\"/>")
    for (x, s) in xticks
        print(io, line(project(X(x), -0.5, zf), project(X(x), 0.5, zf)), text(project(X(x), -0.5, zf) .+ (-8, 28, 0), s))
    end
    for (y, s) in yticks
        print(io, line(project(-0.5, Y(y), zf), project(0.5, Y(y), zf)), text(project(0.5, Y(y), zf) .+ (14, 8, 0), s; anchor = "start"))
    end
    base, top = project(0.5, 0.5, zf), project(0.5, 0.5, H(zhi))
    print(io, line(base, top; color = v.axis))
    for (z, s) in zticks
        q = project(0.5, 0.5, H(z))
        print(io, line(q, q .+ (7, 0, 0); color = v.axis), text(q .+ (12, 6, 0), s; anchor = "start"))
    end
    print(io, text(top .+ (0, -16, 0), zlabel), text(project(0.0, -0.5, zf) .+ (-40, 66, 0), xlabel), text(project(0.5, -0.25, zf) .+ (70, 40, 0), ylabel; anchor = "start"))
    for (_, s) in items
        print(io, s)
    end
    print(io, "</svg>")
    return String(take!(io))
end

"Write `name-dark.svg` and `name-light.svg` in `dir`."
function write_surface(dir, name, args...; kwargs...)
    for theme in (:dark, :light)
        write(joinpath(dir, "$name-$theme.svg"), surface_svg(theme, args...; kwargs...))
    end
end
