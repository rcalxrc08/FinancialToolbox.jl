# Pricing and Greeks

## Black and Scholes model

In the Black and Scholes model the prices of a European call and of a European put are

```math
C_{bs}(S, K, r, T, \sigma, d) = S e^{-d T} N(d_1) - K e^{-r T} N(d_2), \qquad
P_{bs}(S, K, r, T, \sigma, d) = K e^{-r T} N(-d_2) - S e^{-d T} N(-d_1)
```

where ``N`` is the cumulative distribution function of a standard Gaussian random variable ([`normcdf`](@ref)) and

```math
d_1 = \frac{\ln\left(\frac{S}{K}\right) + \left(r - d + \frac{\sigma^2}{2}\right) T}{\sigma\sqrt{T}}, \qquad
d_2 = d_1 - \sigma\sqrt{T}
```

with:

- ``S`` the spot price of the underlying;
- ``K`` the strike price;
- ``r`` the risk free rate;
- ``T`` the time to maturity;
- ``\sigma`` the volatility of the underlying;
- ``d`` the dividend yield of the underlying.

[`blsprice`](@ref) takes the arguments in this order, and a last argument that is `true` for a call (the default) and
`false` for a put:

```@example pricing
using FinancialToolbox
S = 100.0; K = 100.0; r = 0.02; T = 1.2; σ = 0.2; d = 0.01
price_call = blsprice(S, K, r, T, σ, d)
```

```@example pricing
price_put = blsprice(S, K, r, T, σ, d, false)
```

The two prices satisfy the put-call parity ``C - P = S e^{-d T} - K e^{-r T}``:

```@example pricing
price_call - price_put ≈ S * exp(-d * T) - K * exp(-r * T)
```

[`blsbin`](@ref) prices the binary (cash-or-nothing) option paying 1, ``e^{-r T} N(\pm d_2)``:

```@example pricing
blsbin(S, K, r, T, σ, d), blsbin(S, K, r, T, σ, d, false)
```

## Black model

The Black model prices options on a forward ``F``:

```math
C_{bk}(F, K, r, T, \sigma) = e^{-r T} \left(F N(d_1) - K N(d_2)\right), \qquad
P_{bk}(F, K, r, T, \sigma) = e^{-r T} \left(K N(-d_2) - F N(-d_1)\right)
```

```math
d_1 = \frac{\ln\left(\frac{F}{K}\right) + \frac{\sigma^2}{2} T}{\sigma\sqrt{T}}, \qquad d_2 = d_1 - \sigma\sqrt{T}
```

```@example pricing
F = 100.0; K = 102.0
blkprice(F, K, r, T, σ), blkprice(F, K, r, T, σ, false)
```

It is the Black and Scholes price with the forward as spot and a dividend yield equal to the rate:

```@example pricing
blkprice(F, K, r, T, σ) ≈ blsprice(F, K, r, T, σ, r)
```

## Greeks

The sensitivities of the Black and Scholes price take the same arguments as [`blsprice`](@ref):

| Function | Greek | Definition |
|:--|:--|:--|
| [`blsdelta`](@ref) | delta | ``\partial_S V`` |
| [`blsgamma`](@ref) | gamma | ``\partial^2_S V`` |
| [`blsvega`](@ref) | vega | ``\partial_\sigma V`` |
| [`blsrho`](@ref) | rho | ``\partial_r V`` |
| [`blstheta`](@ref) | theta | ``-\partial_T V`` |
| [`blspsi`](@ref) | psi | ``\partial_d V`` |
| [`blslambda`](@ref) | lambda | ``\partial_S V \, S / V`` |
| [`blsvanna`](@ref) | vanna | ``\partial_S \partial_\sigma V`` |

![Price, delta, gamma and vega of a call and a put as functions of the spot](assets/figures/greeks-light.svg)![Price, delta, gamma and vega of a call and a put as functions of the spot](assets/figures/greeks-dark.svg)

```@example pricing
K = 100.0
greeks = (blsdelta, blsgamma, blsvega, blsrho, blstheta, blspsi, blslambda, blsvanna)
[nameof(f) => (f(S, K, r, T, σ, d), f(S, K, r, T, σ, d, false)) for f in greeks]
```

The closed form Greeks agree with automatic differentiation of the price, here with
[ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl):

```@example pricing
using ForwardDiff
ForwardDiff.gradient(x -> blsprice(x[1], K, x[2], x[3], x[4], x[5]), [S, r, T, σ, d])  # S, r, T, σ, d
```

```@example pricing
[blsdelta(S, K, r, T, σ, d), blsrho(S, K, r, T, σ, d), -blstheta(S, K, r, T, σ, d), blsvega(S, K, r, T, σ, d), blspsi(S, K, r, T, σ, d)]
```
