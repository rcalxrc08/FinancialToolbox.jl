# Shared by the test files: each one includes it, so that it also runs alone, e.g.
#     julia --project=test -e 'include("test/core/pricing.jl")'
using Test, FinancialToolbox

# The option of the reference values, as in the Matlab Financial Toolbox: spot, strike, rate, maturity, volatility, dividend
const REFERENCE = (S0 = 10.0, K = 10.0, r = 0.02, T = 2.0, σ = 0.2, d = 0.01)

# Values of the Matlab Financial Toolbox at REFERENCE
const MATLAB = (
    call = (price = 1.191201316999582, binary = 0.4533139191104102, delta = 0.572434050810368, theta = -0.303776337550247, rho = 9.066278382208203, lambda = 4.805518955034612),
    put = (price = 0.997108975455260, binary = 0.507475520041913, delta = -0.407764622496387, theta = -0.209638317050458, rho = -10.149510400838260, lambda = -4.089468980160465),
    black = 1.080531820066428, # call and put: at the money forward
    gamma = 0.135178479404601,
    vega = 5.407139176184034
)

# Closed form sensitivities at REFERENCE: the references of the derivatives computed with the number types.
# theta is -∂price/∂T, psi ∂price/∂d, vanna ∂delta/∂σ.
function closed_form_greeks(FlagIsCall::Bool)
    x = (REFERENCE.S0, REFERENCE.K, REFERENCE.r, REFERENCE.T, REFERENCE.σ, REFERENCE.d)
    return (price = blsprice(x..., FlagIsCall), delta = blsdelta(x..., FlagIsCall), gamma = blsgamma(x..., FlagIsCall), vega = blsvega(x..., FlagIsCall), rho = blsrho(x..., FlagIsCall), theta = blstheta(x..., FlagIsCall), psi = blspsi(x..., FlagIsCall), vanna = blsvanna(x..., FlagIsCall))
end

# Barrier options: QuantLib 1.32 AnalyticBarrierEngine (continuous monitoring, rebate 0) at S0 = 100, r = 8%, d = 4%,
# σ = 25%, T = 1, barrier 95 (down) and 105 (up), strikes below, at and above the barrier: (call, put)
const BARRIER_POINT = (S0 = 100.0, r = 0.08, T = 1.0, σ = 0.25, d = 0.04)
const QUANTLIB_BARRIER = ((blsdownout, 95.0, 90.0, 6.635233733716632, 0.0), (blsdownout, 95.0, 95.0, 5.856901954480392, 0.0), (blsdownout, 95.0, 110.0, 3.647577557242709, 0.12567094047102856), (blsdownin, 95.0, 90.0, 10.229527620472304, 3.866288613753845), (blsdownin, 95.0, 95.0, 8.074308778133954, 5.548319724112432), (blsdownin, 95.0, 110.0, 3.688113352001057, 12.673874156070344), (blsupout, 105.0, 90.0, 0.12153473434133488, 1.7868502551812817), (blsupout, 105.0, 105.0, 0.0, 3.728670408105252), (blsupout, 105.0, 110.0, 0.0, 4.416455370527025), (blsupin, 105.0, 90.0, 16.7432266198476, 2.0794383585725633), (blsupin, 105.0, 105.0, 9.18155003975506, 6.301152087014245), (blsupin, 105.0, 110.0, 7.335690909243766, 8.383089726014347))

# The derivatives every number type and AD backend is checked against, the same references for all of them: one case
# per function, flag and point, with the value, the gradient with respect to every real input and the second derivative
# with respect to S0. blsprice from its closed form Greeks; the barrier options, which have none, by central
# differences in BigFloat (256 bits, step 1e-25: error far below Float64, independent of any AD rule).
function bigfloat_derivatives(f, x, FlagIsCall)
    setprecision(BigFloat, 256) do
        y = big.(collect(x))
        h = big"1e-25"
        g(z) = f(z..., FlagIsCall)
        bump(i, s) = (z = copy(y); z[i] += s; z)
        gradient = ntuple(i -> Float64((g(bump(i, h)) - g(bump(i, -h))) / (2h)), length(x))
        hg = big"1e-18"
        gamma = Float64((g(bump(1, hg)) - 2 * g(y) + g(bump(1, -hg))) / hg^2)
        return gradient, gamma
    end
end
function derivative_cases()
    cases = []
    for FlagIsCall in (true, false)
        x = (REFERENCE.S0, REFERENCE.K, REFERENCE.r, REFERENCE.T, REFERENCE.σ, REFERENCE.d)
        g = closed_form_greeks(FlagIsCall)
        # ∂/∂K = ∓ e^{-rT} N(±d2)
        dK = (FlagIsCall ? -1 : 1) * blsbin(x..., FlagIsCall)
        push!(cases, (name = "blsprice $(FlagIsCall ? "call" : "put")", f = blsprice, x = x, FlagIsCall = FlagIsCall, value = g.price, gradient = (g.delta, dK, g.rho, -g.theta, g.vega, g.psi), gamma = g.gamma))
    end
    (; S0, r, T, σ, d) = BARRIER_POINT
    for (f, H, K, call, put) in QUANTLIB_BARRIER, (FlagIsCall, value) in ((true, call), (false, put))
        x = (S0, K, r, T, σ, d, H)
        gradient, gamma = bigfloat_derivatives(f, x, FlagIsCall)
        push!(cases, (name = "$f $(FlagIsCall ? "call" : "put") K = $K", f = f, x = x, FlagIsCall = FlagIsCall, value = value, gradient = gradient, gamma = gamma))
    end
    return cases
end
const DERIVATIVE_CASES = derivative_cases()

# x with seed applied to its i-th element: the input of a forward mode number type
seeded(seed, x, i) = ntuple(j -> j == i ? seed(x[j]) : x[j], length(x))

# Checks a number type or AD backend on every case: gradient(f, x) returns the partials of f(x...) with respect to every
# element of x (optional), gamma(f, x) (optional) the second derivative with respect to x[1]
function test_derivative_cases(gradient = nothing; gamma = nothing, cases = DERIVATIVE_CASES, rtol = 1e-12, atol = 1e-12)
    for case in cases
        f = (y...) -> case.f(y..., case.FlagIsCall)
        @testset "$(case.name)" begin
            if !isnothing(gradient)
                @test all(isapprox.(gradient(f, case.x), case.gradient; rtol = rtol, atol = atol))
            end
            if !isnothing(gamma)
                @test gamma(f, case.x) ≈ case.gamma rtol = 1e-9 atol = 1e-11
            end
        end
    end
end
