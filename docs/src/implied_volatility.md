# Implied volatility

## Black and Scholes model

Given the price ``V`` of a European option, the Black and Scholes implied volatility is the positive number ``\sigma``
that solves

```math
V = C_{bs}(S, K, r, T, \sigma, d) \quad \text{(call)}, \qquad V = P_{bs}(S, K, r, T, \sigma, d) \quad \text{(put)},
```

with the prices of [Pricing and Greeks](pricing.md). [`blsimpv`](@ref) takes the arguments of [`blsprice`](@ref), with
the price in place of the volatility:

```@example impv
using FinancialToolbox
S = 100.0; K = 100.0; r = 0.02; T = 1.2; d = 0.01
call_price = 9.169580760087896
blsimpv(S, K, r, T, call_price, d)
```

```@example impv
put_price = 7.990980449685762
blsimpv(S, K, r, T, put_price, d, false)
```

## Black model

The same for the Black model, with [`blkimpv`](@ref):

```math
V = C_{bk}(F, K, r, T, \sigma) \quad \text{(call)}, \qquad V = P_{bk}(F, K, r, T, \sigma) \quad \text{(put)}.
```

```@example impv
F = 100.0; K = 102.0
blkimpv(F, K, r, T, 7.659923984582901), blkimpv(F, K, r, T, 9.612495404098706, false)
```

## Accuracy

The implied volatility is computed with the 2024 version of Peter Jäckel's
[Let's Be Rational](http://www.jaeckel.org/LetsBeRational.pdf): a rational initial guess on four branches of the
normalised price, then at most two Householder iterations of order four. The result is accurate to the attainable
machine precision for any moneyness, maturity and volatility.

The figure compares, for out of the money options, the implied volatility of a `Float64` price with the implied
volatility of the same price computed in `BigFloat` (256 bits): the difference is within a few units of `eps(Float64)`,
from very low to very high volatilities and up to strikes ``e^4 \approx 55`` times away from the spot. Deep out of the
money prices at low volatility underflow to zero and have no implied volatility.

![Error of blsimpv in Float64 against BigFloat](assets/figures/accuracy-light.svg)![Error of blsimpv in Float64 against BigFloat](assets/figures/accuracy-dark.svg)

Other number types are computed in their own precision: `Float32` in single precision, `BigFloat` with the precision
in use.

```@example impv
price = blsprice(big(S), big(K), big(r), big(T), big"0.2", big(d))
blsimpv(big(S), big(K), big(r), big(T), price, big(d)) - big"0.2"
```

Complex inputs return the analytic continuation of the real implied volatility, the one needed by the complex step
method: the derivative of the implied volatility with respect to the price is the imaginary part of a single
evaluation, divided by the step.

```@example impv
h = 1e-20
imag(blsimpv(S, K, r, T, complex(call_price, h), d)) / h, 1 / blsvega(S, K, r, T, blsimpv(S, K, r, T, call_price, d), d)
```

Inputs outside the domain (a price below the intrinsic value or above its upper bound, a negative maturity, …) throw a
`DomainError`.
