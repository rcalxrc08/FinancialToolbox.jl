# Implied Black volatility following "Let's Be Rational" by Peter Jäckel, after the 2024 reference implementation
# (www.jaeckel.org/LetsBeRational.7z, revision 1520), © 2013-2024 Peter Jäckel:
#   Permission to use, copy, modify, and distribute this software is freely granted, provided that this notice is preserved.
#   WARRANTY DISCLAIMER: The Software is provided "as is" without warranty of any kind, either express or implied,
#   including without limitation any implied warranties of condition, uninterrupted use, merchantability, fitness
#   for a particular purpose, or non-infringement.
# The Remez-optimised rational approximations are tuned for Float64; Float32 evaluates them in Float32, other floating
# point types use them with (at most) Float64 accuracy in the initial guess and the exact formulas elsewhere.

using MuladdMacro
using IrrationalConstants: IrrationalConstants, sqrt2, invsqrt2, sqrt2π, invsqrt2π, sqrthalfπ, log2π, sqrt3
using SpecialFunctions: erf, erfc, erfcx, erfinv

IrrationalConstants.@irrational twoπ_over_sqrt27 2 * big(π) / sqrt(big(27))
IrrationalConstants.@irrational sqrt3_over_cbrt2π sqrt(big(3)) / cbrt(2 * big(π))
IrrationalConstants.@irrational twoinvsqrtπ 2 / sqrt(big(π))
IrrationalConstants.@irrational erf_half_sqrtπ erf(sqrt(big(π)) / 2) # b_u/b_max for x → 0
IrrationalConstants.@irrational Φ1_minus_half erf(1 / sqrt(big(2))) / 2 Phi1MinusHalf # Φ(1) - ½

square(x) = x * x
dbl_min(::T) where {T <: Number} = eps(zero(T))
dbl_max(::T) where {T <: Number} = prevfloat(typemax(T))
dbl_epsilon(::T) where {T <: Number} = eps(T)
sixteenth_root(x) = sqrt(sqrt(sqrt(sqrt(x))))

# Float64 literals (Remez coefficients and thresholds) in the type of x, so that Float32 is not promoted (constant folded);
# other types take the literal as it is.
typed_literal(x::Union{Float32, Float64}, c) = oftype(x, c)
typed_literal(_, c) = c
# Rational function p(x)/q(x) of coefficient tuples, by Horner's scheme with muladd (evalpoly)
@inline rational_function(x, p, q) = evalpoly(x, map(c -> typed_literal(x, c), p)) / evalpoly(x, map(c -> typed_literal(x, c), q))

include("financial_lets_be_rational_coefficients.jl")

## Rational cubic interpolation (rationalcubic.cpp)

minimum_rational_cubic_control_parameter_value(x) = -(1 - sqrt(dbl_epsilon(x)))
maximum_rational_cubic_control_parameter_value(x) = 2 / square(dbl_epsilon(x))
is_zero(x) = abs(x) < dbl_min(x)

function rational_cubic_interpolation(x, x_l, x_r, y_l, y_r, d_l, d_r, r)
    h = x_r - x_l
    if abs(h) <= 0
        return (y_l + y_r) / 2
    end
    t = (x - x_l) / h
    omt = 1 - t
    if !(r >= maximum_rational_cubic_control_parameter_value(r))
        t2 = square(t)
        return @muladd (y_r * t2 * t + omt * ((r * y_r - h * d_r) * t2 + omt * ((r * y_l + h * d_l) * t + y_l * omt))) / (1 + (r - 3) * t * omt)
    end
    return y_r * t + y_l * omt
end

function rational_cubic_control_parameter_to_fit_second_derivative_at_left_side(x_l, x_r, y_l, y_r, d_l, d_r, second_derivative_l)
    h = x_r - x_l
    @muladd numerator = h * second_derivative_l / 2 + d_r - d_l
    denominator = (y_r - y_l) / h - d_l
    if is_zero(denominator)
        return ifelse(numerator > 0, maximum_rational_cubic_control_parameter_value(denominator), minimum_rational_cubic_control_parameter_value(denominator))
    end
    return numerator / denominator
end

function rational_cubic_control_parameter_to_fit_second_derivative_at_right_side(x_l, x_r, y_l, y_r, d_l, d_r, second_derivative_r)
    h = x_r - x_l
    @muladd numerator = h * second_derivative_r / 2 + d_r - d_l
    denominator = d_r - (y_r - y_l) / h
    if is_zero(denominator)
        return ifelse(numerator > 0, maximum_rational_cubic_control_parameter_value(denominator), minimum_rational_cubic_control_parameter_value(denominator))
    end
    return numerator / denominator
end

function minimum_rational_cubic_control_parameter(d_l, d_r, s, prefer_shape_preservation_over_smoothness)
    monotonic = d_l * s >= 0 && d_r * s >= 0
    convex = d_l <= s && s <= d_r
    concave = d_l >= s && s >= d_r
    zero_typed = zero(d_l * d_r * s)
    if !monotonic && !convex && !concave
        return minimum_rational_cubic_control_parameter_value(zero_typed)
    end
    d_r_m_d_l = d_r - d_l
    d_r_m_s = d_r - s
    s_m_d_l = s - d_l
    r1 = -dbl_max(zero_typed)
    r2 = r1
    if monotonic
        if !is_zero(s)
            r1 = (d_r + d_l) / s
        elseif prefer_shape_preservation_over_smoothness
            r1 = maximum_rational_cubic_control_parameter_value(zero_typed)
        end
    end
    if convex || concave
        if !(is_zero(s_m_d_l) || is_zero(d_r_m_s))
            r2 = max(abs(d_r_m_d_l / d_r_m_s), abs(d_r_m_d_l / s_m_d_l))
        elseif prefer_shape_preservation_over_smoothness
            r2 = maximum_rational_cubic_control_parameter_value(zero_typed)
        end
    elseif monotonic && prefer_shape_preservation_over_smoothness
        r2 = maximum_rational_cubic_control_parameter_value(zero_typed)
    end
    return max(minimum_rational_cubic_control_parameter_value(zero_typed), r1, r2)
end

function convex_rational_cubic_control_parameter_to_fit_second_derivative_at_left_side(x_l, x_r, y_l, y_r, d_l, d_r, second_derivative_l, prefer_shape_preservation_over_smoothness)
    r = rational_cubic_control_parameter_to_fit_second_derivative_at_left_side(x_l, x_r, y_l, y_r, d_l, d_r, second_derivative_l)
    r_min = minimum_rational_cubic_control_parameter(d_l, d_r, (y_r - y_l) / (x_r - x_l), prefer_shape_preservation_over_smoothness)
    return max(r, r_min)
end

function convex_rational_cubic_control_parameter_to_fit_second_derivative_at_right_side(x_l, x_r, y_l, y_r, d_l, d_r, second_derivative_r, prefer_shape_preservation_over_smoothness)
    r = rational_cubic_control_parameter_to_fit_second_derivative_at_right_side(x_l, x_r, y_l, y_r, d_l, d_r, second_derivative_r)
    r_min = minimum_rational_cubic_control_parameter(d_l, d_r, (y_r - y_l) / (x_r - x_l), prefer_shape_preservation_over_smoothness)
    return max(r, r_min)
end

## Inverse cumulative normal "PJ-2024-Inverse-Normal" (normaldistribution.cpp)

function inverse_norm_cdf_for_low_probabilities(p)
    r = sqrt(-log(p))
    if r < typed_literal(r, 6.7)
        if r < typed_literal(r, 3.41)
            if r < typed_literal(r, 2.05)
                return rational_function(r, (3.691562302945566191, 4.7170590600740689449E1, 6.5451292110261454609E1, -7.4594687726045926821E1, -8.3383894003636969722E1, -1.3054072340494093704E1), (1, 2.0837211328697753726E1, 7.1813812182579255459E1, 5.9270122556046077717E1, 9.2216887978737432303, 1.8295174852053530579E-4))
            end
            return rational_function(r, (3.2340179116317970288, 1.449177828689122096E1, 6.8397370256591532878E-1, -1.81254427791789183E1, -1.005916339568646151E1, -1.2013147879435525574E0), (1, 8.8820931773304337525, 1.4656370665176799712E1, 7.1369811056109768745, 8.4884892199149255469E-1, 1.0957576098829595323E-5))
        end
        return rational_function(r, (3.1252235780087584807, 9.9483724317036560676, -5.1633929115525534628, -1.1070534689309368061E1, -2.8699061335882526744, -1.5414319494013597492E-1), (1, 7.076769154309171622, 8.1086341122361532407, 2.0307076064309043613, 1.0897972234131828901E-1, 1.3565983564441297634E-7))
    end
    if r < typed_literal(r, 12.9)
        return rational_function(r, (2.6161264950897283681, 2.250881388987032271, -3.688196041019692267, -2.9644251353150605663, -4.7595169546783216436E-1, -1.612303318390145052E-2), (1, 3.2517455169035921495, 2.1282030272153188194, 3.3663746405626400164E-1, 1.1400087282177594359E-2, 3.0848093570966787291E-9))
    end
    return rational_function(r, (2.3226849047872302955, -4.2799650734502094297E-2, -2.5894451568465728432, -8.6385181219213758847E-1, -6.5127593753781672404E-2, -1.0566357727202585402E-3), (1, 1.9361316119254412206, 6.1320841329197493341E-1, 4.6054974512474443189E-2, 7.471447992167225483E-4, 2.3135343206304887818E-11))
end

# Midrange approximation for |p - ½| < Φ(1) - ½, in s = (Φ(1) - ½)² - u²
function inverse_norm_cdf_minus_half_for_midrange_probabilities(u)
    s = (Φ1_minus_half - abs(u)) * (Φ1_minus_half + abs(u))
    return u * rational_function(s, (2.92958954698308805, 5.0260572167303103E1, 3.01870541922933937E2, 7.4997781456657924E2, 6.90489242061408612E2, 1.34233243502653864E2, -7.58939881401259242), (1, 1.8918538074574598E1, 1.29404120448755281E2, 3.86821208540417453E2, 4.79123914509756757E2, 1.79227008508102628E2))
end

function inverse_norm_cdf(p)
    u = p - 1 // 2
    if abs(u) < Φ1_minus_half
        return inverse_norm_cdf_minus_half_for_midrange_probabilities(u)
    end
    return u > 0 ? -inverse_norm_cdf_for_low_probabilities(1 - p) : inverse_norm_cdf_for_low_probabilities(p)
end

## Normalised Black function b(x, s) for x < 0, with h := x/s and t := s/2

const ETA = -13 # η
const CODY_THRESHOLD = 0.46875 # where erfc and erfcx switch algorithm (and the lower bound of the Remez approximation of Y')

# The asymptotic expansion (Region I), the extent of Region II and the Remez approximations of Y'(h) are tuned for Float64,
# and also used for Float32 (where they are more accurate than needed); other types use the exact formulas.
uses_double_approximations(x) = x isa Union{Float32, Float64}
# τ = 2·ε^(1/16), with the ε of Float64 for the types using the double approximations
tau(x) = uses_double_approximations(x) ? oftype(x, 2 * sixteenth_root(eps(Float64))) : 2 * sixteenth_root(dbl_epsilon(x))
# Region I: h < η, t < (τ+½) + (|h|-|η|). Region II: t < τ + (½/|η|)·|h|. Region III: otherwise.
is_region_I(x, s) = uses_double_approximations(s) && x < s * ETA && s * (s / 2 - (tau(s) + 1 // 2 + ETA)) + x < 0
# For other types Region II is the original t < τ, since the wider 2024 region is calibrated for Float64 accuracy
is_region_II(x, s) = uses_double_approximations(s) ? s * (s - 2 * tau(s)) - x / ETA < 0 : s < 2 * tau(s)

# Asymptotic expansion of the scaled normalised Black function b/(∂b/∂s) = Y(h+t) - Y(h-t), Y(z) := Φ(z)/φ(z), in Region I.
# The number of terms depends on the distance from the upper border of the region (thresholds from the reference implementation).
@muladd function asymptotic_expansion_of_scaled_normalised_black(h, t)
    e = square(t / h)
    r = (h + t) * (h - t)
    q = square(h / r)
    d = -h - t + tau(h) + 1 // 2
    k = count(≤(d), map(c -> typed_literal(d, c), (12.347, 12.958, 13.729, 14.718, 16.016, 17.769, 20.221, 23.816, 29.419, 38.93, 57.171, 99.347)))
    ω = zero(q)
    k <= 0 && (ω = q * (asymptotic_coefficient_16(e) + ω))
    k <= 1 && (ω = q * (asymptotic_coefficient_15(e) + ω))
    k <= 2 && (ω = q * (asymptotic_coefficient_14(e) + ω))
    k <= 3 && (ω = q * (asymptotic_coefficient_13(e) + ω))
    k <= 4 && (ω = q * (asymptotic_coefficient_12(e) + ω))
    k <= 5 && (ω = q * (asymptotic_coefficient_11(e) + ω))
    k <= 6 && (ω = q * (asymptotic_coefficient_10(e) + ω))
    k <= 7 && (ω = q * (asymptotic_coefficient_9(e) + ω))
    k <= 8 && (ω = q * (asymptotic_coefficient_8(e) + ω))
    k <= 9 && (ω = q * (asymptotic_coefficient_7(e) + ω))
    k <= 10 && (ω = q * (asymptotic_coefficient_6(e) + ω))
    k <= 11 && (ω = q * (asymptotic_coefficient_5(e) + ω))
    ω = asymptotic_coefficient_0(e) + q * (asymptotic_coefficient_1(e) + q * (asymptotic_coefficient_2(e) + q * (asymptotic_coefficient_3(e) + q * (asymptotic_coefficient_4(e) + ω))))
    return (t / r) * ω
end

# Y'(h) = 1 + h·Y(h) without subtractive cancellation (Remez-optimised rational functions for h ≤ -0.46875)
function Yprime(h)
    if uses_double_approximations(h)
        if h < -4
            w = inv(square(h))
            return @muladd w * (1 + w * rational_function(w, (-2.9999999999994663866, -1.7556263323542206288E2, -3.4735035445495633334E3, -2.7805745693864308643E4, -8.3836021460741980839E4, -6.6818249032616849037E4), (1, 6.3520877744831739102E1, 1.4404389037604337538E3, 1.4562545638507033944E4, 6.6886794165651675684E4, 1.2569970380923908488E5, 6.9286518679803751694E4)))
        end
        if h <= -typed_literal(h, CODY_THRESHOLD)
            return rational_function(-h, (1.0000000000594317229, 6.1911449879694112749E-1, 2.2180844736576013957E-1, 4.5650900351352987865E-2, 5.545521007735379052E-3, 3.0717392274913902347E-4, 4.2766597835908713583E-8, -8.4592436406580605619E-10), (1, 1.8724286369589162071, 1.5685497236077651429, 7.6576489836589035112E-1, 2.3677701403094640361E-1, 4.6762548903194957675E-2, 5.5290453576936595892E-3, 3.0822020417927147113E-4))
        end
    end
    return @muladd 1 + h * sqrthalfπ * erfcx(-(invsqrt2 * h))
end

# Small-t expansion of the scaled normalised Black function in Region II (only odd orders in t, seven terms)
@muladd function small_t_expansion_of_scaled_normalised_black(h, t)
    a = Yprime(h)
    h² = square(h)
    t² = square(t)
    B0 = 2 * a
    B1 = (-1 + a * (3 + h²)) / 3
    B2 = (-7 - h² + a * (15 + h² * (10 + h²))) / 60
    B3 = (-57 + (-18 - h²) * h² + a * (105 + h² * (105 + h² * (21 + h²)))) / 2520
    B4 = (-561 + h² * (-285 + (-33 - h²) * h²) + a * (945 + h² * (1260 + h² * (378 + h² * (36 + h²))))) / 181440
    B5 = (-6555 + h² * (-4680 + h² * (-840 + (-52 - h²) * h²)) + a * (10395 + h² * (17325 + h² * (6930 + h² * (990 + h² * (55 + h²)))))) / 19958400
    B6 = (-89055 + h² * (-82845 + h² * (-20370 + h² * (-1926 + (-75 - h²) * h²))) + a * (135135 + h² * (270270 + h² * (135135 + h² * (25740 + h² * (2145 + h² * (78 + h²))))))) / 3113510400
    return t * (B0 + t² * (B1 + t² * (B2 + t² * (B3 + t² * (B4 + t² * (B5 + B6 * t²))))))
end

# Region III: b = ½·[exp(x/2)·erfc(q₁) - exp(-x/2)·erfc(q₂)], q₁ = -(h+t)/√2, q₂ = -(h-t)/√2, with erfc(q) = erfcx(q)·exp(-q²)
# where that saves exponentials. The exponentials are passed in: b_max = exp(x/2) is fixed by x, and
# E = exp(-(h²+t²)/2) = exp(x/2-q₁²) = exp(-x/2-q₂²) = √(2π)·∂b/∂s is shared with the vega.
function normalised_black_with_optimal_use_of_codys_functions(q₁, q₂, b_max, E)
    threshold = typed_literal(q₁, CODY_THRESHOLD)
    if q₁ < threshold
        if q₂ < threshold
            two_b = b_max * erfc(q₁) - erfc(q₂) / b_max
        else
            two_b = b_max * erfc(q₁) - E * erfcx(q₂)
        end
    elseif q₂ < threshold
        two_b = E * erfcx(q₁) - erfc(q₂) / b_max
    else
        two_b = E * (erfcx(q₁) - erfcx(q₂))
    end
    return max(two_b / 2, zero(two_b))
end

inv_normalised_vega(x, s) = sqrt2π * exp((square(x / s) + square(s / 2)) / 2)

# b(x, s) for s > 0 and x < 0, given h = x/s, t = s/2, b_max and E (see above)
function normalised_black(x, s, h, t, b_max, E)
    if is_region_I(x, s)
        return asymptotic_expansion_of_scaled_normalised_black(h, t) * (invsqrt2π * E)
    end
    if is_region_II(x, s)
        return small_t_expansion_of_scaled_normalised_black(h, t) * (invsqrt2π * E)
    end
    return normalised_black_with_optimal_use_of_codys_functions(-(invsqrt2 * (h + t)), -(invsqrt2 * (h - t)), b_max, E)
end

# b/b' (so that ln(b) = ln(b/b') + ln(b') is available without underflow in the lowest branch), given h, t, b_max and
# h² + t² = -2·ln(√(2π)·b')
function scaled_normalised_black(x, s, h, t, b_max, h²_plus_t²)
    if is_region_I(x, s)
        return asymptotic_expansion_of_scaled_normalised_black(h, t)
    end
    if is_region_II(x, s)
        return small_t_expansion_of_scaled_normalised_black(h, t)
    end
    q₁ = -(invsqrt2 * (h + t))
    q₂ = -(invsqrt2 * (h - t))
    threshold = typed_literal(q₁, CODY_THRESHOLD)
    if q₁ >= threshold && q₂ >= threshold # E cancels: b/b' = √(π/2)·(erfcx(q₁) - erfcx(q₂))
        return max(sqrthalfπ * (erfcx(q₁) - erfcx(q₂)), zero(q₁))
    end
    E = exp(-h²_plus_t² / 2)
    return normalised_black_with_optimal_use_of_codys_functions(q₁, q₂, b_max, E) * sqrt2π / E
end

## Initial guess: maps of the lowest and highest branch, and b_l, b_u

@muladd function compute_f_lower_map_and_first_two_derivatives(x, s)
    ax = abs(x)
    z = ax / (sqrt3 * s)
    y = square(z)
    s2 = square(s)
    # With Φ := Φ(-z) = erfcx(z/√2)·exp(-y/2)/2 and Φ/φ(z) = √(π/2)·erfcx(z/√2) the exponentials partly cancel:
    # f = (2π/√27)·|x|·Φ³, f' = 2π·y·Φ²·exp(y + s²/8), f'' = (π/6)·(y/s³)·Φ·(8√3·s·|x| + (3s²(s²-8) - 8x²)·Φ/φ)·exp(2y + s²/4)
    ex = erfcx(invsqrt2 * z)
    exp_y = exp(-3 * y / 2) # = (2Φ/erfcx)³
    exp_s = exp(s2 / 8)
    fpp = π * y / (12 * s2 * s) * ex * (8 * (sqrt3 * s * ax) + (3 * s2 * (s2 - 8) - 8 * square(x)) * (sqrthalfπ * ex)) * (square(exp_s) / exp_y)
    fp = π * y * square(ex) * exp_s / 2
    f = twoπ_over_sqrt27 * ax * (square(ex) * ex) * exp_y / 8
    return f, fp, fpp
end

inverse_f_lower_map(x, f) = abs(x / (sqrt3 * inverse_norm_cdf(sqrt3_over_cbrt2π * cbrt(f / abs(x)))))

@muladd function compute_f_upper_map_and_first_two_derivatives(x, s)
    f = erfc(invsqrt2 * s / 2) / 2
    w = square(x / s)
    fp = -exp(w / 2) / 2
    fpp = sqrthalfπ * exp(w + square(s) / 8) * w / s
    return f, fp, fpp
end

inverse_f_upper_map(f) = -2 * inverse_norm_cdf(f)

# 1 - erfcx(x) without cancellation for small x
function one_minus_erfcx(x)
    if 5 * x < -1 || 3 * x > 1
        return 1 - erfcx(x)
    end
    return @muladd x * (twoinvsqrtπ - x * rational_function(x, (1.0000000000000002, 1.1514967181784756, 5.7689001208873741E-1, 1.4069188744609651E-1, 1.4069285713634565E-2), (1, 1.9037494962421563, 1.5089908593742723, 6.2486081658640257E-1, 1.358008134514386E-1, 1.2463320728346347E-2)))
end

# b_l(x)/b_max(x) and b_u(x)/b_max(x) as functions of s_c = √(2|x|), Remez-optimised in four branches each.
# The branches are bounded by square roots of rationals, compared as s_c² against the rationals.
function bl_over_bmax(s_c)
    s_c² = square(s_c)
    if 10 * s_c² < 69 # s_c < √6.9
        if 125 * s_c² < 63 # s_c < √0.504
            g = rational_function(s_c, (8.0741072372882856924E-2, 9.8078911786358897272E-2, 3.9760631445677058375E-2, 5.9716928459589189876E-3, -6.4036399341479799981E-6, 4.5425102093616062245E-7), (1, 1.8594977672287664353, 1.3658801475711790419, 4.6132707108655653215E-1, 6.1254597049831720643E-2))
            return @muladd s_c² * (typed_literal(s_c, 0.07560996640296361767172) + s_c * (s_c * g - typed_literal(s_c, 0.09672719281339436290858)))
        end
        return rational_function(s_c, (1.9795737927598581235E-9, -2.7081288564685588037E-8, 7.5610142272549044609E-2, 6.917130174466834016E-2, 2.9537058950963019803E-2, 6.5849252702302307774E-3, 6.9711400639834715731E-4), (1, 2.1941448525586579756, 2.1297103549995181357, 1.1571483187179784072, 3.7831622253060456794E-1, 7.1714862448829349869E-2, 6.6361975827861200167E-3))
    end
    if s_c² < 54 # s_c < √54
        return rational_function(s_c, (-9.3325115354837883291E-5, 5.3118033972794648837E-4, 7.4114855448345002595E-2, 7.4039658186822817454E-2, 3.9225177407687604785E-2, 1.0022913378254090083E-2, 1.7012579407246055469E-3), (1, 2.2217238132228132256, 2.3441816707087403282, 1.3912323646271141826, 5.3231258443501838354E-1, 1.1744005919716101572E-1, 1.6195405895930935811E-2))
    end
    return rational_function(s_c, (1.4500072297240603183E-3, -1.5116692485011195757E-3, 7.1682178310936334831E-2, 3.921610857820463493E-2, 2.9342405658628443931E-2, 5.1832526171631521426E-3, 1.6930208078421474854E-3), (1, 1.6176313502305414664, 1.6823159175281531664, 8.4878307567372222113E-1, 3.7543742137375791321E-1, 7.126137099644302999E-2, 1.6116992546788676159E-2))
end

function bu_over_bmax(s_c)
    s_c² = square(s_c)
    if 5 * s_c² < 16 # s_c < 4/√5
        if 5 * s_c² < 3 # s_c < √(3/5)
            g = rational_function(s_c, (-6.063099881233561706E-2, -8.1011946637120604985E-2, -4.2505564862438753828E-2, -8.9880000946868691788E-3, -7.5603072110443268356E-6, 4.3879556621540147458E-7), (1, 1.8400371530721828756, 1.5709283443886143691, 6.8913245453611400484E-1, 1.4703173061720980923E-1))
            return @muladd erf_half_sqrtπ + s_c² * (typed_literal(s_c, 0.0614616805805147403487) + s_c * g)
        end
        return rational_function(s_c, (7.8990944435755287611E-1, -1.2655410534988972886, -2.8803040699221003256, -2.6936198689113258727, -1.1213067281643205754, -2.1277793801691629892E-1, 5.1486445905299802703E-6), (1, -1.6021222722060444448, -3.7242680976480704555, -3.2083117718907365085, -1.2922333835930958583, -2.3762328334050001161E-1))
    end
    if s_c² < 38 # s_c < √38
        return rational_function(s_c, (7.8990640048967596475E-1, 1.5993699253596663678, 1.6481729039140370242, 9.8227188109869200166E-1, 3.6313557966186936883E-1, 7.8277036261179606301E-2, 9.3404307364538726214E-3), (1, 2.0247407005640401446, 2.0087454279103740489, 1.1627561803056961973, 4.2004672123723823581E-1, 8.9130862793887234546E-2, 1.0436767768858021717E-2))
    end
    return rational_function(s_c, (7.91133825948419359E-1, 1.24653733210880042, 1.32747426980537386, 6.95009705717846778E-1, 3.05965944268228457E-1, 6.02200363391352887E-2, 1.29050244454344842E-2), (1, 1.58117486714634672, 1.60144713247629644, 8.30040185836882436E-1, 3.53071863813401531E-1, 6.95901684131758475E-2, 1.44197580643890011E-2))
end

## Iteration

# Householder factors of order 3 and 4 for the Newton step n and the ratios h₂, h₃, h₄ of the derivatives of the objective
@muladd householder3_factor(n, h₂, h₃) = (1 + h₂ * n / 2) / (1 + n * (h₂ + h₃ * n / 6))
@muladd householder4_factor(n, h₂, h₃, h₄) = (1 + n * (h₂ + n * h₃ / 6)) / (1 + n * (3 * h₂ / 2 + n * (square(h₂) / 4 + h₃ / 3 + n * h₄ / 24)))

# Normalised implied volatility for an out-of-the-money normalised price β (x ≤ 0), with at most N Householder iterations
@muladd function lets_be_rational(β, x, N)
    zero_typed = zero(β * x)
    if β <= 0
        return zero_typed
    end
    b_max = exp(x / 2)
    if x == 0 # at the money: b(0,s) = erf(s/√8)
        return sqrt2 * (2 * erfinv(β))
    end
    tol = cbrt(dbl_epsilon(zero_typed)) # Householder(3) is 4th order: after a step ds the error is O(ds^4)
    iterations = 0
    f = -dbl_max(zero_typed)
    s = f
    ds = f
    sqrt_ax = sqrt(-x)
    s_c = sqrt2 * sqrt_ax
    ome = one_minus_erfcx(sqrt_ax)
    b_c = b_max * ome / 2
    if β < b_c
        s_l = s_c - ome * sqrthalfπ # (not sqrthalfπ * ome: @muladd would negate the Irrational, promoting to Float64)
        b_l = bl_over_bmax(s_c) * b_max
        if β < b_l
            # Lowest branch: objective g(s) = 1/ln(b(s)) - 1/ln(β)
            f_l, fp_l, fpp_l = compute_f_lower_map_and_first_two_derivatives(x, s_l)
            r_ll = convex_rational_cubic_control_parameter_to_fit_second_derivative_at_right_side(zero_typed, b_l, zero_typed, f_l, one(zero_typed), fp_l, fpp_l, true)
            f = rational_cubic_interpolation(β, zero_typed, b_l, zero_typed, f_l, one(zero_typed), fp_l, r_ll)
            if !(f > 0) # roundoff for extreme |x|: quadratic interpolation with f(0)=0, f(b_l), f'(0)=1
                t = β / b_l
                f = (f_l * t + b_l * (1 - t)) * t
            end
            s = inverse_f_lower_map(x, f)
            ln_β = log(β)
            inv_ln_β = inv(ln_β)
            while iterations < N && abs(ds) > tol * s
                iterations += 1
                h = x / s
                t = s / 2
                h² = square(h)
                h²_plus_t² = h² + square(t)
                bx = scaled_normalised_black(x, s, h, t, b_max, h²_plus_t²)
                ln_b = log(bx) - (log2π + h²_plus_t²) / 2 # ln(b/b') + ln(b')
                bpob = inv(bx)
                x²_over_s³ = h² / s
                b_h₂ = x²_over_s³ - s / 4
                newton = (ln_β - ln_b) * ln_b * inv_ln_β * bx
                λ = inv(ln_b)
                otλ = 1 + 2 * λ
                h₂ = b_h₂ - bpob * otλ
                c = 3 * (x²_over_s³ / s)
                b_h₃ = square(b_h₂) - c - 1 // 4
                sq_bpob = square(bpob)
                bppob = b_h₂ * bpob
                μ = 6 * λ * (1 + λ)
                h₃ = b_h₃ + sq_bpob * (2 + μ) - bppob * 3 * otλ
                if x < -190 # Householder(4) for extreme moneyness
                    h₄ = (b_h₂ * (b_h₃ - 1 // 2) - (b_h₂ - 2 / s) * 2 * c) - bpob * (sq_bpob * (6 + λ * (22 + λ * (36 + λ * 24))) - bppob * (12 + 6 * μ)) - bppob * b_h₂ * 3 * otλ - b_h₃ * bpob * 4 * otλ
                    ds = newton * householder4_factor(newton, h₂, h₃, h₄)
                else
                    ds = newton * householder3_factor(newton, h₂, h₃)
                end
                s += ds
            end
            return s
        end
        # Lower middle: s_l ≤ s < s_c
        inv_v_c = sqrt2π / b_max
        inv_v_l = inv_normalised_vega(x, s_l)
        r_lm = convex_rational_cubic_control_parameter_to_fit_second_derivative_at_right_side(b_l, b_c, s_l, s_c, inv_v_l, inv_v_c, zero_typed, false)
        s = rational_cubic_interpolation(β, b_l, b_c, s_l, s_c, inv_v_l, inv_v_c, r_lm)
    else
        s_u = s_c + sqrthalfπ * (2 - ome)
        b_u = bu_over_bmax(s_c) * b_max
        if β <= b_u
            # Upper middle: s_c ≤ s ≤ s_u
            inv_v_c = sqrt2π / b_max
            inv_v_u = inv_normalised_vega(x, s_u)
            r_um = convex_rational_cubic_control_parameter_to_fit_second_derivative_at_left_side(b_c, b_u, s_c, s_u, inv_v_c, inv_v_u, zero_typed, false)
            s = rational_cubic_interpolation(β, b_c, b_u, s_c, s_u, inv_v_c, inv_v_u, r_um)
        else
            # Highest branch
            f_u, fp_u, fpp_u = compute_f_upper_map_and_first_two_derivatives(x, s_u)
            sqrt_dbl_max = sqrt(dbl_max(zero_typed))
            if fpp_u > -sqrt_dbl_max && fpp_u < sqrt_dbl_max
                r_uu = convex_rational_cubic_control_parameter_to_fit_second_derivative_at_left_side(b_u, b_max, f_u, zero_typed, fp_u, -one(zero_typed) / 2, fpp_u, true)
                f = rational_cubic_interpolation(β, b_u, b_max, f_u, zero_typed, fp_u, -one(zero_typed) / 2, r_uu)
            end
            if f <= 0 # quadratic interpolation with f(b_u), f(b_max)=0, f'(b_max)=-1/2
                h = b_max - b_u
                t = (β - b_u) / h
                f = (f_u * (1 - t) + h * t / 2) * (1 - t)
            end
            s = inverse_f_upper_map(f)
            if β > b_max / 2
                # Objective g(s) = ln(b_max-β) - ln(b_max-b(s)) using the complementary normalised Black function b̄ = b_max - b
                β_bar = b_max - β
                while iterations < N && abs(ds) > tol * s
                    iterations += 1
                    h = x / s
                    t = s / 2
                    h² = square(h)
                    # b̄ = exp(-(h²+t²)/2)·(erfcx((t+h)/√2) + erfcx((t-h)/√2))/2 and b' = exp(-(h²+t²)/2)/√(2π)
                    erfcx_sum = erfcx((t + h) * invsqrt2) + erfcx((t - h) * invsqrt2)
                    gp = invsqrt2π * (2 / erfcx_sum) # b'/b̄
                    b_bar = exp(-(h² + square(t)) / 2) * erfcx_sum / 2
                    g = log(β_bar / b_bar)
                    x²_over_s³ = h² / s
                    b_h₂ = x²_over_s³ - s / 4
                    c = 3 * (x²_over_s³ / s)
                    b_h₃ = square(b_h₂) - c - 1 // 4
                    newton = -g / gp
                    h₂ = b_h₂ + gp
                    h₃ = b_h₃ + gp * (2 * gp + 3 * b_h₂)
                    if x < -580 # Householder(4) for extreme moneyness
                        h₄ = (b_h₂ * (b_h₃ - 1 // 2) - (b_h₂ - 2 / s) * 2 * c) + gp * (6 * gp * (gp + 2 * b_h₂) + 3 * square(b_h₂) + 4 * b_h₃)
                        ds = newton * householder4_factor(newton, h₂, h₃, h₄)
                    else
                        ds = newton * householder3_factor(newton, h₂, h₃)
                    end
                    s += ds
                end
                return s
            end
        end
    end
    # Middle branches: objective g(s) = b(s) - β
    while iterations < N && abs(ds) > tol * s
        iterations += 1
        h = x / s
        t = s / 2
        h² = square(h)
        E = exp(-(h² + square(t)) / 2) # √(2π)·b'
        newton = (β - normalised_black(x, s, h, t, b_max, E)) * sqrt2π / E
        x²_over_s³ = h² / s
        h₂ = x²_over_s³ - s / 4
        h₃ = square(h₂) - 3 * (x²_over_s³ / s) - 1 // 4
        ds = newton * householder3_factor(newton, h₂, h₃)
        s += ds
    end
    return s
end

# In the money options are mapped to out of the money ones (price - intrinsic is the price of the opposite option)
function blimpv_lets_be_rational(F, K, T, price, FlagIsCall::Bool, ::Real, niter::Integer)
    intrinsic = ifelse(FlagIsCall, F - K, K - F)
    β = (intrinsic > 0 ? price - intrinsic : price) / (sqrt(F) * sqrt(K))
    σ = lets_be_rational(β, -abs(log(F / K)), niter) / sqrt(T)
    # Types other than Float32 and Float64 (e.g. Float16) may be promoted by the Float64 approximations
    return convert(typeof(β / sqrt(T)), σ)
end
