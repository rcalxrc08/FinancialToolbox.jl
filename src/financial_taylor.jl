using .TaylorSeries

# function integrate_correct(a::Taylor1{T}, x::S) where {T <: Number, S <: Number}
#     order = get_order(a)
#     @views aa = a[0] / 1 + zero(x)
#     R = typeof(aa)
#     coeffs = Array{typeof(aa)}(undef, order + 2)
#     # fill!(coeffs, zero(aa))
#     @inbounds @views coeffs[1] = convert(R, x)
#     @inbounds for i = 1:order+1
#         @views coeffs[i+1] = a[i-1] / i
#     end
#     return Taylor1(coeffs)
# end

function mul_internal(f_der::Taylor1{T}, x::Taylor1{T}, k::Int) where {T <: Number}
    k_1 = k + 1
    @views @inbounds res = sum(f_der[i] * x[k_1-i] * (k_1 - i) for i = 0:k)
    return res / k_1
end

function mul_and_integrate(f_der::Taylor1{T}, x::Taylor1{T}, y::S) where {T <: Number, S <: Number}
    order = get_order(x)
    res = Array{Float64}(undef, order + 1)
    res_t = Taylor1(res)
    @views @inbounds res_t[0] = y
    @inbounds for i = 1:order
        @views res_t[i] = mul_internal(f_der, x, i - 1)
    end
    return res_t
end

# function define_diff_rule(f, df)
#     @eval function (op::typeof($f))(x::Taylor1)
#         @views val = x[0]
#         normpdf_res = ($df)(x)
#         return FinancialToolbox.mul_and_integrate(normpdf_res, x, ($f)(val))
#     end
# end
# define_diff_rule(normcdf, normpdf)
function FinancialToolbox.normcdf(x::Taylor1)
    @views val = x[0]
    # x_adj=Taylor1(x.co)
    normpdf_res = normpdf(x)
    # der = derivative(x)
    return mul_and_integrate(normpdf_res, x, normcdf(val))
end

# function mul2!(c::HomogeneousPolynomial, a::HomogeneousPolynomial, b::HomogeneousPolynomial)
#     (iszero(b) || iszero(a)) && return nothing

#     @inbounds num_coeffs_a = size_table[a.order+1]
#     @inbounds num_coeffs_b = size_table[b.order]

#     @inbounds posTb = pos_table[c.order+1]

#     @inbounds indTa = index_table[a.order+1]
#     @inbounds indTb = index_table[b.order]

#     @inbounds for na = 1:num_coeffs_a
#         ca = a[na]
#         # iszero(ca) && continue
#         inda = indTa[na]

#         @inbounds for nb = 1:num_coeffs_b
#             cb = b[1+nb]
#             # iszero(cb) && continue
#             indb = indTb[nb]

#             pos = posTb[inda+indb]
#             c[pos] += ca * cb
#         end
#     end

#     return nothing
# end
function mul_and_integrate(f_der::TaylorN{T}, x::TaylorN{T}, y::S) where {T <: Number, S <: Number}
    order = get_order(x)
    res_t = Taylor1(order)
    @views @inbounds res_t[0] = y
    @inbounds for i = 1:order
        @views res_t[i] = mul_internal(f_der, x, i - 1)
    end
    return res_t
end
# TODO: move to proper implementation: https://github.com/JuliaDiff/TaylorSeries.jl/issues/285
function FinancialToolbox.normcdf(x::TaylorN)
    Nmax = 20000
    xmin = -20.0
    x_ = range(xmin, length = Nmax, stop = x)
    dx = (x - xmin) / (Nmax - 1)
    return sum(FinancialToolbox.normpdf.(x_)) * dx
end
# function normcdf2(x::TaylorN)
#     @views val = x[0][1]
#     normpdf_res = normpdf(x)
#     grad = TaylorSeries.gradient(x)
#     # PriceCall2-integrate(derivative(PriceCall2,3),3,PriceCall2[0][1])
#     extreme_points2 = [(x - val - integrate(derivative(x, i), i)) for i in eachindex(grad)]
#     # normpdf_res_adj = [(normpdf_res[0][1] + integrate(derivative(normpdf_res, i), i)) for i in eachindex(grad)]
#     # @show grad
#     # extreme_points2 = [sum(integrate(derivative(x, j), j) for j in eachindex(grad) if i != j) for i in eachindex(grad)]
#     @show extreme_points2
#     return normcdf(val) + sum(integrate(normpdf_res * grad[i], i, extreme_points2[i]) for i in eachindex(grad)) #- tmp_el
# end

# function normcdf3(x::TaylorN)
#     @views val = x[0][1]
#     normpdf_res = normpdf(x)
#     # grad = TaylorSeries.gradient(x)
#     # PriceCall2-integrate(derivative(PriceCall2,3),3,PriceCall2[0][1])
#     # extreme_points = [(x - val - integrate(derivative(x, i), i)) for i in eachindex(grad)]
#     # extreme_points = [(x - val - integrate(derivative(x, i), i)) for i in eachindex(grad)]
#     # @show extreme_points
#     # TaylorN([HomogeneousPolynomial([0.0]), HomogeneousPolynomial([0.0, 1.0, 1.0])])
#     return normcdf(x[0][1]) + integrate(normpdf_res * derivative(x, 1), 1, x - integrate(derivative(x, 1), 1, x[0][1]))
#     # return normcdf(val) + sum(integrate(normpdf_res * grad[i], i, extreme_points[i][0][1]) for i in eachindex(grad)) #- tmp_el
# end

value__d(x::Taylor1) = @views x[0]
value__d(x::TaylorN) = @views x[0][1]
value__d(x) = x
!hasmethod(isless, (Taylor1, Taylor1)) ? (Base.isless(x::Taylor1, y::Taylor1) = @views value__d(x) < value__d(y)) : nothing
!hasmethod(isless, (TaylorN, TaylorN)) ? (Base.isless(x::TaylorN, y::TaylorN) = @views value__d(x) < value__d(y)) : nothing

# function blsimpv_impl(::Taylor1, S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
#     S0_r = value__d(S0)
#     K_r = value__d(K)
#     r_r = value__d(r)
#     T_r = value__d(T)
#     p_r = value__d(price_d)
#     d_r = value__d(d)
#     sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r, FlagIsCall, xtol, ytol)
#     der_ = (price_d - blsprice(S0, K, r, T, sigma, d, FlagIsCall)) / blsvega(S0_r, K_r, r_r, T_r, sigma, d_r)
#     out = sigma + der_
#     return out
# end
get_order_adj(x::Taylor1) = get_order(x)
get_order_adj(::Any) = 0
function blsimpv_impl(::Taylor1, S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
    S0_r = value__d(S0)
    K_r = value__d(K)
    r_r = value__d(r)
    T_r = value__d(T)
    p_r = value__d(price_d)
    d_r = value__d(d)
    sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r, FlagIsCall, xtol, ytol)
    max_order = maximum(map(x -> get_order_adj(x), (S0, K, r, T, price_d, d)))
    vega = blsvega(S0_r, K_r, r_r, T_r, sigma, d_r)
    σ_coeffs = Array{Float64}(undef, max_order + 1)
    @views σ_coeffs[1] = sigma
    @inbounds for i = 1:max_order
        # @show σ_coeffs
        cur_sigma = Taylor1(deepcopy(σ_coeffs), i)
        # cur_sigma += (price_d - blsprice(S0, K, r, T, cur_sigma, d, FlagIsCall))
        cur_sigma += (price_d - blsprice(S0, K, r, T, cur_sigma, d, FlagIsCall)) / vega
        # @views σ_coeffs[i+1] = cur_sigma[i] / vega
        @views σ_coeffs[i+1] = cur_sigma[i]
    end
    return Taylor1(σ_coeffs)
end
# function blsimpv_impl(::TaylorN, S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
#     S0_r = value__d(S0)
#     K_r = value__d(K)
#     r_r = value__d(r)
#     T_r = value__d(T)
#     p_r = value__d(price_d)
#     d_r = value__d(d)
#     sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r, FlagIsCall, xtol, ytol)
#     der_ = (price_d - blsprice(S0, K, r, T, sigma, d, FlagIsCall)) / blsvega(S0_r, K_r, r_r, T_r, sigma, d_r, FlagIsCall)
#     out = sigma + der_
#     return out
# end

@inline function blsimpv_impl(::TaylorN, S0, K, r, T, price_d, d, FlagIsCall, xtol, ytol)
    zero_type = S0 * K * r * T * d * price_d * 0
    S0_r = value__d(S0)
    K_r = value__d(K)
    r_r = value__d(r)
    T_r = value__d(T)
    p_r = value__d(price_d)
    d_r = value__d(d)
    sigma = blsimpv(S0_r, K_r, r_r, T_r, p_r, d_r, FlagIsCall, xtol, ytol)
    max_order = get_order(zero_type)
    vega = blsvega(S0_r, K_r, r_r, T_r, sigma, d_r)
    σ_coeffs = Array{Float64}[]
    # σ_coeffs = Array{Array{Float64}}(undef, get_order(zero_type) + 1)
    # σ_coeffs = Array{Float64}(undef, max_order + 1)
    push!(σ_coeffs, [sigma])
    # @views σ_coeffs[1] = [sigma]
    for i = 1:max_order
        @show σ_coeffs
        cur_sigma = TaylorN(HomogeneousPolynomial.(deepcopy(σ_coeffs)))
        @show cur_sigma
        @show price_d - blsprice(S0, K, r, T, cur_sigma, d, FlagIsCall)
        cur_sigma += (price_d - blsprice(S0, K, r, T, cur_sigma, d, FlagIsCall)) / vega
        @show cur_sigma
        σ_der = cur_sigma[i-1]
        push!(σ_coeffs, σ_der.coeffs)
        # @views σ_coefkfs[i+1] = σ_der
    end
    return TaylorN(HomogeneousPolynomial.(σ_coeffs))
    # return Taylor1(σ_coeffs)
end