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
    vega = 5.407139176184034,
)

# Closed form sensitivities at REFERENCE: the references of the derivatives computed with the number types.
# theta is -∂price/∂T, psi ∂price/∂d, vanna ∂delta/∂σ.
function closed_form_greeks(FlagIsCall::Bool)
    x = (REFERENCE.S0, REFERENCE.K, REFERENCE.r, REFERENCE.T, REFERENCE.σ, REFERENCE.d)
    return (
        price = blsprice(x..., FlagIsCall),
        delta = blsdelta(x..., FlagIsCall),
        gamma = blsgamma(x..., FlagIsCall),
        vega = blsvega(x..., FlagIsCall),
        rho = blsrho(x..., FlagIsCall),
        theta = blstheta(x..., FlagIsCall),
        psi = blspsi(x..., FlagIsCall),
        vanna = blsvanna(x..., FlagIsCall),
    )
end
