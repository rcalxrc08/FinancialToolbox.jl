
using MuladdMacro

function dbl_min(::T) where {T <: Number}
    return eps(zero(T))
end

function dbl_max(::T) where {T <: Number}
    return prevfloat(typemax(T))
end
using IrrationalConstants
function dbl_epsilon(::T) where {T <: Number}
    return eps(T)
end
function minimum_rational_cubic_control_parameter_value(x)
    return -(1 - sqrt(dbl_epsilon(x)))
end
square(x) = x^2
positive_part(x::T) where {T <: Number} = max(x, zero(T))
function maximum_rational_cubic_control_parameter_value(x)
    return 2 / square(dbl_epsilon(x))
end

const norm_cdf_asymptotic_expansion_first_threshold = -10;

function rational_cubic_interpolation(x, x_l, x_r, y_l, y_r, d_l, d_r, r)
    h = (x_r - x_l)
    if (abs(h) <= 0)
        return (y_l + y_r) / 2
    end
    # r should be greater than -1. We do not use  assert(r > -1)  here in order to allow values such as NaN to be propagated as they should.
    t = (x - x_l) / h
    omt = 1 - t
    if (!(r >= maximum_rational_cubic_control_parameter_value(r)))
        t2 = square(t)
        # omt2 = square(omt)
        # Formula (2.4) divided by formula (2.5)
        # return @muladd (y_r * t2 * t + (r * y_r - h * d_r) * t2 * omt + (r * y_l + h * d_l) * t * omt2 + y_l * omt2 * omt) / (1 + (r - 3) * t * omt)
        # return @muladd (y_r * t2 * t + (r * y_r - h * d_r) * t2 * omt + omt2 * ((r * y_l + h * d_l) * t + y_l * omt)) / (1 + (r - 3) * t * omt)
        return @muladd (y_r * t2 * t + omt * ((r * y_r - h * d_r) * t2 + omt * ((r * y_l + h * d_l) * t + y_l * omt))) / (1 + (r - 3) * t * omt)
    end
    # Linear interpolation without over-or underflow.
    return y_r * t + y_l * omt
end
is_zero(x) = abs(x) < dbl_min(x);

function rational_cubic_control_parameter_to_fit_second_derivative_at_left_side(x_l, x_r, y_l, y_r, d_l, d_r, second_derivative_l)
    h = (x_r - x_l)
    @muladd numerator = h * second_derivative_l / 2 + d_r - d_l
    zero_num = zero(numerator)
    if (is_zero(numerator))
        return zero_num
    end
    denominator = (y_r - y_l) / h - d_l
    zero_typed = zero_num + zero(denominator)
    if (is_zero(denominator))
        return ifelse(numerator > 0, maximum_rational_cubic_control_parameter_value(zero_typed), minimum_rational_cubic_control_parameter_value(zero_typed))
    end
    return numerator / denominator
end

function rational_cubic_control_parameter_to_fit_second_derivative_at_right_side(x_l, x_r, y_l, y_r, d_l, d_r, second_derivative_r)
    h = (x_r - x_l)
    @muladd numerator = h * second_derivative_r / 2 + d_r - d_l
    zero_num = zero(numerator)
    if (is_zero(numerator))
        return zero_num
    end
    denominator = d_r - (y_r - y_l) / h
    zero_typed = zero_num + zero(denominator)
    if (is_zero(denominator))
        return ifelse(numerator > 0, maximum_rational_cubic_control_parameter_value(zero_typed), minimum_rational_cubic_control_parameter_value(zero_typed))
    end
    return numerator / denominator
end

function minimum_rational_cubic_control_parameter(d_l::T, d_r::U, s::V, prefer_shape_preservation_over_smoothness) where {T <: Real, U <: Real, V <: Real}
    monotonic = d_l * s >= 0 && d_r * s >= 0
    convex = d_l <= s && s <= d_r
    concave = d_l >= s && s >= d_r
    zero_typed = zero(promote_type(T, U, V))
    if (!monotonic && !convex && !concave) # If 3==r_non_shape_preserving_target, this means revert to standard cubic.
        return minimum_rational_cubic_control_parameter_value(zero_typed)
    end
    d_r_m_d_l = d_r - d_l
    d_r_m_s = d_r - s
    s_m_d_l = s - d_l
    r1 = -dbl_max(zero_typed)
    r2 = r1
    # If monotonicity on this interval is possible, set r1 to satisfy the monotonicity condition (3.8).
    if (monotonic)
        if (!is_zero(s)) # (3.8), avoiding division by zero.
            r1 = (d_r + d_l) / s # (3.8)
        elseif (prefer_shape_preservation_over_smoothness) # If division by zero would occur, and shape preservation is preferred, set value to enforce linear interpolation.
            r1 = maximum_rational_cubic_control_parameter_value(zero_typed)  # This value enforces linear interpolation.
        end
    end
    if (convex || concave)
        if (!(is_zero(s_m_d_l) || is_zero(d_r_m_s))) # (3.18), avoiding division by zero.
            r2 = max(abs(d_r_m_d_l / d_r_m_s), abs(d_r_m_d_l / s_m_d_l))
        elseif (prefer_shape_preservation_over_smoothness)
            r2 = maximum_rational_cubic_control_parameter_value(zero_typed) # This value enforces linear interpolation.
        end
    elseif (monotonic && prefer_shape_preservation_over_smoothness)
        r2 = maximum_rational_cubic_control_parameter_value(zero_typed) # This enforces linear interpolation along segments that are inconsistent with the slopes on the boundaries, e.g., a perfectly horizontal segment that has negative slopes on either edge.
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

function sqrt_dbl_epsilon(x)
    return sqrt(dbl_epsilon(x))
end
function fourth_root_dbl_epsilon(x)
    return sqrt(sqrt_dbl_epsilon(x))
end
function eighth_root_dbl_epsilon(x)
    return sqrt(fourth_root_dbl_epsilon(x))
end
function sixteenth_root_dbl_epsilon(x)
    return sqrt(eighth_root_dbl_epsilon(x))
end
function sqrt_dbl_min(x)
    return sqrt(dbl_min(x))
end

# Set this to 0 if you want positive results for (positive) denormalised inputs, else to dbl_min.
# Note that you cannot achieve full machine accuracy from denormalised inputs!

householder_factor(newton, halley, hh3) = @muladd (1 + halley * newton / 2) / (1 + newton * (halley + hh3 * newton / 6));

# Asymptotic expansion of
#
#              b  =  Φ(h+t)·exp(x/2) - Φ(h-t)·exp(-x/2)
# with
#              h  =  x/s   and   t  =  s/2
# which makes
#              b  =  Φ(h+t)·exp(h·t) - Φ(h-t)·exp(-h·t)
#
#                    exp(-(h²+t²)/2)
#                 =  ---------------  ·  [ Y(h+t) - Y(h-t) ]
#                        √(2π)
# with
#           Y(z) := Φ(z)/φ(z)
#
# for large negative (t-|h|) by the aid of Abramowitz & Stegun (26.2.12) where Φ(z) = φ(z)/|z|·[1-1/z^2+...].
# We define
#                     r
#         A(h,t) :=  --- · [ Y(h+t) - Y(h-t) ]
#                     t
#
# with r := (h+t)·(h-t) and give an expansion for A(h,t) in q:=(h/r)² expressed in terms of e:=(t/h)² .
function asymptotic_expansion_of_normalised_black_call(h, t)
    e = square(t / h)
    r = (h + t) * (h - t)
    q = square(h / r)
    twice_e = 2 * e
    # 17th order asymptotic expansion of A(h,t) in q, sufficient for Φ(h) [and thus y(h)] to have relative accuracy of 1.64E-16 for h <= η  with  η:=-10.
    #TODO: this is too much for "less" than Float64
    @muladd asymptotic_expansion_sum = (
        2 +
        q * (
            -6 - twice_e +
            3 *
            q *
            (
                10 +
                e * (20 + twice_e) +
                5 *
                q *
                (
                    -14 +
                    e * (-70 + e * (-42 - twice_e)) +
                    7 *
                    q *
                    (
                        18 +
                        e * (168 + e * (252 + e * (72 + twice_e))) +
                        9 *
                        q *
                        (
                            -22 +
                            e * (-330 + e * (-924 + e * (-660 + e * (-110 - twice_e)))) +
                            11 *
                            q *
                            (
                                26 +
                                e * (572 + e * (2574 + e * (3432 + e * (1430 + e * (156 + twice_e))))) +
                                13 *
                                q *
                                (
                                    -30 +
                                    e * (-910 + e * (-6006 + e * (-12870 + e * (-10010 + e * (-2730 + e * (-210 - twice_e)))))) +
                                    15 *
                                    q *
                                    (
                                        34 +
                                        e * (1360 + e * (12376 + e * (38896 + e * (48620 + e * (24752 + e * (4760 + e * (272 + twice_e))))))) +
                                        17 *
                                        q *
                                        (
                                            -38 +
                                            e * (-1938 + e * (-23256 + e * (-100776 + e * (-184756 + e * (-151164 + e * (-54264 + e * (-7752 + e * (-342 - twice_e)))))))) +
                                            19 *
                                            q *
                                            (
                                                42 +
                                                e * (2660 + e * (40698 + e * (232560 + e * (587860 + e * (705432 + e * (406980 + e * (108528 + e * (11970 + e * (420 + twice_e))))))))) +
                                                21 *
                                                q *
                                                (
                                                    -46 +
                                                    e * (-3542 + e * (-67298 + e * (-490314 + e * (-1634380 + e * (-2704156 + e * (-2288132 + e * (-980628 + e * (-201894 + e * (-17710 + e * (-506 - twice_e)))))))))) +
                                                    23 *
                                                    q *
                                                    (
                                                        50 +
                                                        e * (4600 + e * (106260 + e * (961400 + e * (4085950 + e * (8914800 + e * (10400600 + e * (6537520 + e * (2163150 + e * (354200 + e * (25300 + e * (600 + twice_e))))))))))) +
                                                        25 *
                                                        q *
                                                        (
                                                            -54 +
                                                            e * (-5850 + e * (-161460 + e * (-1776060 + e * (-9373650 + e * (-26075790 + e * (-40116600 + e * (-34767720 + e * (-16872570 + e * (-4440150 + e * (-592020 + e * (-35100 + e * (-702 - twice_e)))))))))))) +
                                                            27 * q * (58 + e * (7308 + e * (237510 + e * (3121560 + e * (20030010 + e * (69194580 + e * (135727830 + e * (155117520 + e * (103791870 + e * (40060020 + e * (8584290 + e * (950040 + e * (47502 + e * (812 + twice_e))))))))))))) + 29 * q * (-62 + e * (-8990 + e * (-339822 + e * (-5259150 + e * (-40320150 + e * (-169344630 + e * (-412506150 + e * (-601080390 + e * (-530365050 + e * (-282241050 + e * (-88704330 + e * (-15777450 + e * (-1472562 + e * (-62930 + e * (-930 - twice_e)))))))))))))) + 31 * q * (66 + e * (10912 + e * (474672 + e * (8544096 + e * (77134200 + e * (387073440 + e * (1146332880 + e * (2074316640 + e * (2333606220 + e * (1637618400 + e * (709634640 + e * (185122080 + e * (27768312 + e * (2215136 + e * (81840 + e * (1056 + twice_e))))))))))))))) + 33 * (-70 + e * (-13090 + e * (-649264 + e * (-13449040 + e * (-141214920 + e * (-834451800 + e * (-2952675600 + e * (-6495886320 + e * (-9075135300 + e * (-8119857900 + e * (-4639918800 + e * (-1668903600 + e * (-367158792 + e * (-47071640 + e * (-3246320 + e * (-104720 + e * (-1190 - twice_e))))))))))))))))) * q)))
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
    z = exp((-(square(h) + square(t)) / 2))
    b = z * (t / r) * asymptotic_expansion_sum / sqrt2π
    return abs(positive_part(b))
end

const asymptotic_expansion_accuracy_threshold = -10

function normalised_black_call_using_erfcx(h, t)
    # Given h = x/s and t = s/2, the normalised Black function can be written as
    #
    #     b(x,s)  =  Φ(x/s+s/2)·exp(x/2)  -   Φ(x/s-s/2)·exp(-x/2)
    #             =  Φ(h+t)·exp(h·t)      -   Φ(h-t)·exp(-h·t) .                     (*)
    #
    # It is mentioned in section 4 (and discussion of figures 2 and 3) of George Marsaglia's article "Evaluating the
    # Normal Distribution" (available at http:#www.jstatsoft.org/v11/a05/paper) that the error of any cumulative normal
    # function Φ(z) is dominated by the hardware (or compiler implementation) accuracy of exp(-z²/2) which is not
    # reliably more than 14 digits when z is large. The accuracy of Φ(z) typically starts coming down to 14 digits when
    # z is around -8. For the (normalised) Black function, as above in (*), this means that we are subtracting two terms
    # that are each products of terms with about 14 digits of accuracy. The net result, in each of the products, is even
    # less accuracy, and then we are taking the difference of these terms, resulting in even less accuracy. When we are
    # using the asymptotic expansion asymptotic_expansion_of_normalised_black_call() invoked in the second branch at the
    # beginning of this function, we are using only *one* exponential instead of 4, and this improves accuracy. It
    # actually improves it a bit more than you would expect from the above logic, namely, almost the full two missing
    # digits (in 64 bit IEEE floating point).  Unfortunately, going higher order in the asymptotic expansion will not
    # enable us to gain more accuracy (by extending the range in which we could use the expansion) since the asymptotic
    # expansion, being a divergent series, can never gain 16 digits of accuracy for z=-8 or just below. The best you can
    # get is about 15 digits (just), for about 35 terms in the series (26.2.12), which would result in an prohibitively
    # long expression in function asymptotic expansion asymptotic_expansion_of_normalised_black_call(). In this last branch,
    # here, we therefore take a different tack as follows.
    #     The "scaled complementary error function" is defined as erfcx(z) = exp(z²)·erfc(z). Cody's implementation of this
    # function as published in "Rational Chebyshev approximations for the error function", W. J. Cody, Math. Comp., 1969, pp.
    # 631-638, uses rational functions that theoretically approximates erfcx(x) to at least 18 significant decimal digits,
    # *without* the use of the exponential function when x>4, which translates to about z<-5.66 in Φ(z). To make use of it,
    # we write
    #             Φ(z) = exp(-z²/2)·erfcx(-z/√2)/2
    #
    # to transform the normalised black function to
    #
    #   b   =  ½ · exp(-½(h²+t²)) · [ erfcx(-(h+t)/√2) -  erfcx(-(h-t)/√2) ]
    #
    # which now involves only one exponential, instead of three, when |h|+|t| > 5.66 , and the difference inside the
    # square bracket is between the evaluation of two rational functions, which, typically, according to Marsaglia,
    # retains the full 16 digits of accuracy (or just a little less than that).
    #
    arg_minus = (t - h) / sqrt2
    arg_plus = (-t - h) / sqrt2
    b = exp(-(square(h) + square(t)) / 2) * (erfcx(arg_plus) - erfcx(arg_minus)) / 2
    return abs(positive_part(b))
end

# Calculation of
#
#              b  =  Φ(h+t)·exp(h·t) - Φ(h-t)·exp(-h·t)
#
#                    exp(-(h²+t²)/2)
#                 =  --------------- ·  [ Y(h+t) - Y(h-t) ]
#                        √(2π)
# with
#           Y(z) := Φ(z)/φ(z)
#
# using an expansion of Y(h+t)-Y(h-t) for small t to twelvth order in t.
# Theoretically accurate to (better than) precision  ε = 2.23E-16  when  h<=0  and  t < τ  with  τ := 2·ε^(1/16) ≈ 0.21.
# The main bottleneck for precision is the coefficient a:=1+h·Y(h) when |h|>1 .
function small_t_expansion_of_normalised_black_call(h, t)
    # Y(h) := Φ(h)/φ(h) = √(π/2)·erfcx(-h/√2)
    # a := 1+h·Y(h)  --- Note that due to h<0, and h·Y(h) -> -1 (from above) as h -> -∞, we also have that a>0 and a -> 0 as h -> -∞
    # w := t² , h2 := h²
    half_h_sqrt2 = h / sqrt2
    a = 1 + sqrtπ * half_h_sqrt2 * erfcx(-half_h_sqrt2)
    w = square(t)
    h2 = square(h)
    #TODO: this is too much for float "less" than Float64
    @muladd expansion = 2 * t * (a + w * ((-1 + a * (3 + h2)) / 6 + w * ((-7 + 15 * a + h2 * (-1 + a * (10 + h2))) / 120 + w * ((-57 + 105 * a + h2 * (-18 + 105 * a + h2 * (-1 + a * (21 + h2)))) / 5040 + w * ((-561 + 945 * a + h2 * (-285 + 1260 * a + h2 * (-33 + 378 * a + h2 * (-1 + a * (36 + h2))))) / 362880 + w * ((-6555 + 10395 * a + h2 * (-4680 + 17325 * a + h2 * (-840 + 6930 * a + h2 * (-52 + 990 * a + h2 * (-1 + a * (55 + h2)))))) / 39916800 + ((-89055 + 135135 * a + h2 * (-82845 + 270270 * a + h2 * (-20370 + 135135 * a + h2 * (-1926 + 25740 * a + h2 * (-75 + 2145 * a + h2 * (-1 + a * (78 + h2))))))) * w) / 6227020800))))))
    b = exp((-(h2 + w) / 2)) * expansion / sqrt2π
    return abs(positive_part(b))
end

# const small_t_expansion_of_normalised_black_threshold = 2 * sixteenth_root_dbl_epsilon
function small_t_expansion_of_normalised_black_threshold(x)
    return 2 * sixteenth_root_dbl_epsilon(x)
end
#     b(x,s)  =  Φ(x/s+s/2)·exp(x/2)  -   Φ(x/s-s/2)·exp(-x/2)
#             =  Φ(h+t)·exp(x/2)      -   Φ(h-t)·exp(-x/2)
# with
#              h  =  x/s   and   t  =  s/2
function normalised_black_call_using_normcdf(x, s)
    h = x / s
    t = s / 2
    b_max = exp(x / 2)
    @muladd b = normcdf(h + t) * b_max - normcdf(h - t) / b_max
    return abs(positive_part(b))
end

#
# Introduced on 2017-02-18
#
#     b(x,s)  =  Φ(x/s+s/2)·exp(x/2)  -   Φ(x/s-s/2)·exp(-x/2)
#             =  Φ(h+t)·exp(x/2)      -   Φ(h-t)·exp(-x/2)
#             =  ½ · exp(-u²-v²) · [ erfcx(u-v) -  erfcx(u+v) ]
#             =  ½ · [ exp(x/2)·erfc(u-v)     -  exp(-x/2)·erfc(u+v)    ]
#             =  ½ · [ exp(x/2)·erfc(u-v)     -  exp(-u²-v²)·erfcx(u+v) ]
#             =  ½ · [ exp(-u²-v²)·erfcx(u-v) -  exp(-x/2)·erfc(u+v)    ]
# with
#              h  =  x/s ,       t  =  s/2 ,
# and
#              u  = -h/√2  and   v  =  t/√2 .
#
# Cody's erfc() and erfcx() functions each, for some values of their argument, involve the evaluation
# of the exponential function exp(). The normalised Black function requires additional evaluation(s)
# of the exponential function irrespective of which of the above formulations is used. However, the total
# number of exponential function evaluations can be minimised by a judicious choice of one of the above
# formulations depending on the input values and the branch logic in Cody's erfc() and erfcx().
#

function normalised_black_call(x::T, s::V) where {T <: Real, V <: Real}
    if (s <= 0)
        return zero(x) # sigma=0 -> intrinsic value.
    end
    zero_typed = zero(promote_type(T, V))
    small_t_expansion_of_normalised_black_threshold_ = small_t_expansion_of_normalised_black_threshold(zero_typed)
    # Denote h := x/s and t := s/2.
    # We evaluate the condition |h|>|η|, i.e., h<η  &&  t < τ+|h|-|η|  avoiding any divisions by s , where η = asymptotic_expansion_accuracy_threshold  and τ = small_t_expansion_of_normalised_black_threshold .
    s_2 = s / 2
    s_square_mod = square(s) / 2 + x
    z = x / s
    s_div = s_square_mod / s
    if (z < asymptotic_expansion_accuracy_threshold && s_div < (small_t_expansion_of_normalised_black_threshold_ + asymptotic_expansion_accuracy_threshold))
        return asymptotic_expansion_of_normalised_black_call(z, s_2)
    end
    if (s_2 < small_t_expansion_of_normalised_black_threshold_)
        return small_t_expansion_of_normalised_black_call(z, s_2)
    end
    if (s_div > 17 // 20)
        return normalised_black_call_using_normcdf(x, s)
    end
    return normalised_black_call_using_erfcx(z, s_2)
end

function normalised_vega(x::T, s::V) where {T <: Real, V <: Real}
    ax = abs(x)
    zero_typed = zero(promote_type(T, V))
    if (ax <= 0)
        z = exp(-square(s) / 8)
        return z / sqrt2π
    elseif (s <= 0 || s <= ax * sqrt_dbl_min(zero_typed))
        return zero_typed
    end
    return exp(-(square(x / s) + square(s / 2)) / 2) / sqrt2π
end

function normalised_vega_inverse(x::T, s::V) where {T <: Real, V <: Real}
    ax = abs(x)
    zero_typed = zero(promote_type(T, V))
    if (ax <= 0)
        z = exp(square(s) / 8)
        return sqrt2π * z
    elseif (s <= 0 || s <= ax * sqrt_dbl_min(zero_typed))
        return dbl_max(zero_typed)
    end
    return exp((square(x / s) + square(s / 2)) / 2) * sqrt2π
end

function compute_f_lower_map_and_first_two_derivatives(x, s)
    ax = abs(x)
    z = ax / (sqrt3 * s)
    y = square(z)
    s2 = square(s)
    Phi = normcdf(-z)
    phi = normpdf(z)
    exp_y_adj = exp(y + s2 / 8)

    @muladd fpp = pi * y / (6 * s2 * s) * Phi * (8 * s * sqrt3 * ax + (3 * s2 * (s2 - 8) - 8 * square(x)) * Phi / phi) * square(exp_y_adj)
    Phi2 = square(Phi)
    fp = 2 * y * pi * Phi2 * exp_y_adj
    f = twoπ * ax * Phi2 / 3 * Phi / sqrt3
    return f, fp, fpp
end

using SpecialFunctions
function inverse_normcdf(el)
    return -erfcinv(2 * el) * sqrt2
end

function inverse_f_lower_map(x, f)
    y = twoπ * abs(x) / 3
    return abs(x / (sqrt3 * inverse_normcdf(cbrt(sqrt3 * f / y))))
end

function compute_f_upper_map_and_first_two_derivatives(x, s)
    f = normcdf(-s / 2)
    w = square(x / s)
    fp = -exp(w / 2) / 2
    fpp = sqrt2π * exp(w + square(s) / 8) / 2 * w / s
    return f, fp, fpp
end

function inverse_f_upper_map(f)
    return -2 * inverse_normcdf(f)
end

function unchecked_normalised_implied_volatility_from_a_transformed_rational_guess_with_limited_iterations(beta::T, x::V, N) where {T <: Real, V <: Real}
    # Subtract intrinsic.
    typed_zero = zero(promote_type(T, V))
    typed_one = typed_zero + 1
    b_max = exp(x / 2)
    iterations = 0
    direction_reversal_count = 0
    dbl_max_typed = dbl_max(typed_zero)
    dbl_eps_typed = dbl_epsilon(typed_zero)
    dbl_min_typed = dbl_min(typed_zero)
    sqrt_dbl_max_typed = sqrt(dbl_max_typed)
    f = -dbl_max_typed
    s = -dbl_max_typed
    ds = s
    ds_previous = 0
    s_left = dbl_min_typed
    s_right = dbl_max_typed
    # The temptation is great to use the optimised form b_c = exp(x/2)/2-exp(-x/2)·Phi(sqrt(-2·x)) but that would require implementing all of the above types of round-off and over/underflow handling for this expression, too.
    s_c = sqrt(abs(2 * x))
    b_c = normalised_black_call(x, s_c)
    v_c_inv = normalised_vega_inverse(x, s_c)
    # Four branches.
    if (beta < b_c)
        s_l = s_c - b_c * v_c_inv
        b_l = normalised_black_call(x, s_l)
        if (beta < b_l)
            f_lower_map_l, d_f_lower_map_l_d_beta, d2_f_lower_map_l_d_beta2 = compute_f_lower_map_and_first_two_derivatives(x, s_l)
            r_ll = convex_rational_cubic_control_parameter_to_fit_second_derivative_at_right_side(typed_zero, b_l, typed_zero, f_lower_map_l, typed_one, d_f_lower_map_l_d_beta, d2_f_lower_map_l_d_beta2, true)
            f = rational_cubic_interpolation(beta, typed_zero, b_l, typed_zero, f_lower_map_l, typed_one, d_f_lower_map_l_d_beta, r_ll)
            if (!(f > 0))  # This can happen due to roundoff truncation for extreme values such as |x|>500.
                # We switch to quadratic interpolation using f(0)≡0, f(b_l), and f'(0)≡1 to specify the quadratic.
                t = beta / b_l
                @muladd f = (f_lower_map_l * t + b_l * (1 - t)) * t
            end
            s = inverse_f_lower_map(x, f)
            s_right = s_l
            #
            # In this branch, which comprises the lowest segment, the objective function is
            #     g(s) = 1/ln(b(x,s)) - 1/ln(beta)
            #          ≡ 1/ln(b(s)) - 1/ln(beta)
            # This makes
            #              g'               =   -b'/(b·ln(b)²)
            #              newton = -g/g'   =   (ln(beta)-ln(b))·ln(b)/ln(beta)·b/b'
            #              halley = g''/g'  =   b''/b'  -  b'/b·(1+2/ln(b))
            #              hh3    = g'''/g' =   b'''/b' +  2(b'/b)²·(1+3/ln(b)·(1+1/ln(b)))  -  3(b''/b)·(1+2/ln(b))
            #
            # The Householder(3) iteration is
            #     s_n+1  =  s_n  +  newton · [ 1 + halley·newton/2 ] / [ 1 + newton·( halley + hh3·newton/6 ) ]
            #
            while (iterations < N && abs(ds) > dbl_eps_typed * s)
                iterations += 1
                if (ds * ds_previous < 0)
                    direction_reversal_count += 1
                end
                if (iterations > 0 && (3 == direction_reversal_count || !(s > s_left && s < s_right)))
                    # If looping inefficently, or the forecast step takes us outside the bracket, or onto its edges, switch to binary nesting.
                    # NOTE that this can only really happen for very extreme values of |x|, such as |x| = |ln(F/K)| > 500.
                    s = (s_left + s_right) / 2
                    if (s_right - s_left <= dbl_eps_typed * s)
                        break
                    end
                    direction_reversal_count = 0
                    ds = 0
                end
                ds_previous = ds
                b = normalised_black_call(x, s)
                bp = normalised_vega(x, s)
                if (b > beta && s < s_right)
                    s_right = s
                elseif (b < beta && s > s_left)
                    s_left = s # Tighten the bracket if applicable.
                end
                if (b <= 0 || bp <= 0) # Numerical underflow. Switch to binary nesting for this iteration.
                    ds = (s_left + s_right) / 2 - s
                else
                    ln_b = log(b)
                    ln_beta = log(beta)
                    bpob = bp / b
                    h = x / s
                    b_halley = square(h) / s - s / 4
                    newton = (ln_beta - ln_b) * ln_b / ln_beta / bpob
                    inv_lnb = inv(ln_b)
                    @muladd halley = b_halley - bpob * (1 + 2 * inv_lnb)
                    @muladd b_hh3 = square(b_halley) - 3 * square(h / s) - 1 // 4
                    @muladd hh3 = b_hh3 + 2 * square(bpob) * (1 + 3 * inv_lnb * (1 + inv_lnb)) - 3 * b_halley * bpob * (1 + 2 * inv_lnb)
                    ds = newton * householder_factor(newton, halley, hh3)
                end
                ds = max(-s / 2, ds)
                s += ds
            end
            return s
        else
            v_l_inv = normalised_vega_inverse(x, s_l)
            r_lm = convex_rational_cubic_control_parameter_to_fit_second_derivative_at_right_side(b_l, b_c, s_l, s_c, v_l_inv, v_c_inv, typed_zero, false)
            s = rational_cubic_interpolation(beta, b_l, b_c, s_l, s_c, v_l_inv, v_c_inv, r_lm)
            s_left = s_l
            s_right = s_c
        end
    else
        s_h = s_c
        if (v_c_inv < dbl_max_typed)
            s_h += (b_max - b_c) * v_c_inv
        end
        b_h = normalised_black_call(x, s_h)
        if (beta <= b_h)
            v_h_inv = normalised_vega_inverse(x, s_h)
            r_hm = convex_rational_cubic_control_parameter_to_fit_second_derivative_at_left_side(b_c, b_h, s_c, s_h, v_c_inv, v_h_inv, typed_zero, false)
            s = rational_cubic_interpolation(beta, b_c, b_h, s_c, s_h, v_c_inv, v_h_inv, r_hm)
            s_left = s_c
            s_right = s_h
        else
            f_upper_map_h, d_f_upper_map_h_d_beta, d2_f_upper_map_h_d_beta2 = compute_f_upper_map_and_first_two_derivatives(x, s_h)
            if (d2_f_upper_map_h_d_beta2 > -sqrt_dbl_max_typed && d2_f_upper_map_h_d_beta2 < sqrt_dbl_max_typed)
                r_hh = convex_rational_cubic_control_parameter_to_fit_second_derivative_at_left_side(b_h, b_max, f_upper_map_h, typed_zero, d_f_upper_map_h_d_beta, -typed_one * 1 // 2, d2_f_upper_map_h_d_beta2, true)
                f = rational_cubic_interpolation(beta, b_h, b_max, f_upper_map_h, typed_zero, d_f_upper_map_h_d_beta, -typed_one * 1 // 2, r_hh)
            end
            if (f <= 0)
                h = b_max - b_h
                t = (beta - b_h) / h
                omt = 1 - t
                @muladd f = (f_upper_map_h * omt + h * t / 2) * omt # We switch to quadratic interpolation using f(b_h), f(b_max)≡0, and f'(b_max)≡-1/2 to specify the quadratic.
            end
            s = inverse_f_upper_map(f)
            s_left = s_h
            if (beta > b_max / 2)  # Else we better drop through and let the objective function be g(s) = b(x,s)-beta. 
                #
                # In this branch, which comprises the upper segment, the objective function is
                #     g(s) = ln(b_max-beta)-ln(b_max-b(x,s))
                #          ≡ ln((b_max-beta)/(b_max-b(s)))
                # This makes
                #              g'               =   b'/(b_max-b)
                #              newton = -g/g'   =   ln((b_max-b)/(b_max-beta))·(b_max-b)/b'
                #              halley = g''/g'  =   b''/b'  +  b'/(b_max-b)
                #              hh3    = g'''/g' =   b'''/b' +  g'·(2g'+3b''/b')
                # and the iteration is
                #     s_n+1  =  s_n  +  newton · [ 1 + halley·newton/2 ] / [ 1 + newton·( halley + hh3·newton/6 ) ].
                #
                while (iterations < N && abs(ds) > dbl_eps_typed * s)
                    iterations += 1
                    if (ds * ds_previous < 0)
                        direction_reversal_count += 1
                    end
                    if (iterations > 0 && (3 == direction_reversal_count || !(s > s_left && s < s_right)))
                        # If looping inefficently, or the forecast step takes us outside the bracket, or onto its edges, switch to binary nesting.
                        # NOTE that this can only really happen for very extreme values of |x|, such as |x| = |ln(F/K)| > 500.
                        s = (s_left + s_right) / 2
                        if (s_right - s_left <= dbl_eps_typed * s)
                            break
                        end
                        direction_reversal_count = 0
                        ds = 0
                    end
                    ds_previous = ds
                    b = normalised_black_call(x, s)
                    bp = normalised_vega(x, s)
                    if (b > beta && s < s_right)
                        s_right = s
                    elseif (b < beta && s > s_left)
                        s_left = s # Tighten the bracket if applicable.
                    end
                    if (b >= b_max || bp <= dbl_min_typed) # Numerical underflow. Switch to binary nesting for this iteration.
                        ds = (s_left + s_right) / 2 - s
                    else
                        b_max_minus_b = b_max - b
                        g = log((b_max - beta) / b_max_minus_b)
                        gp = bp / b_max_minus_b
                        b_halley = square(x / s) / s - s / 4
                        @muladd b_hh3 = square(b_halley) - 3 * square(x / square(s)) - 1 // 4
                        newton = -g / gp
                        halley = b_halley + gp
                        @muladd hh3 = b_hh3 + gp * (2 * gp + 3 * b_halley)
                        ds = newton * householder_factor(newton, halley, hh3)
                    end
                    ds = max(-s / 2, ds)
                    s += ds
                end
                return s
            end
        end
    end
    # In this branch, which comprises the two middle segments, the objective function is g(s) = b(x,s)-beta, or g(s) = b(s) - beta, for short.
    # This makes
    #              newton = -g/g'   =  -(b-beta)/b'
    #              halley = g''/g'  =    b''/b'    =  x²/s³-s/4
    #              hh3    = g'''/g' =    b'''/b'   =  halley² - 3·(x/s²)² - 1/4
    # and the iteration is
    #     s_n+1  =  s_n  +  newton · [ 1 + halley·newton/2 ] / [ 1 + newton·( halley + hh3·newton/6 ) ].
    #
    while (iterations < N && abs(ds) > dbl_eps_typed * s)
        iterations += 1
        if (ds * ds_previous < 0)
            direction_reversal_count += 1
        end
        if (iterations > 0 && (3 == direction_reversal_count || !(s > s_left && s < s_right)))
            # If looping inefficently, or the forecast step takes us outside the bracket, or onto its edges, switch to binary nesting.
            # NOTE that this can only really happen for very extreme values of |x|, such as |x| = |ln(F/K)| > 500.
            s = (s_left + s_right) / 2
            if (s_right - s_left <= dbl_eps_typed * s)
                break
            end
            direction_reversal_count = 0
            ds = 0
        end
        ds_previous = ds
        b = normalised_black_call(x, s)
        bp_inv = normalised_vega_inverse(x, s)
        if (b > beta && s < s_right)
            s_right = s
        elseif (b < beta && s > s_left)
            s_left = s # Tighten the bracket if applicable.
        end
        newton = (beta - b) * bp_inv
        halley = square(x / s) / s - s / 4
        hh3 = square(halley) - 3 * square(x / square(s)) - 1 // 4
        ds = max(-s / 2, newton * householder_factor(newton, halley, hh3))
        s += ds
    end
    return s
end

function new_blimpv(F::num1, K::num2, T::num4, price::num5, FlagIsCall::Bool, ::Real, niter::Integer) where {num1, num2, num4, num5}
    x = log(F / K)
    q = ifelse(FlagIsCall, 1, -1)
    return unchecked_normalised_implied_volatility_from_a_transformed_rational_guess_with_limited_iterations(price / sqrt(F * K), x * q, niter) / sqrt(T)
end
