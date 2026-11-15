```@raw html
<div class="fc-page-head">
<p class="fc-kicker"><span>Guide 02</span> Knock-outs and knock-ins in closed form</p>
```

# Barrier options


```@raw html
<div class="fc-meta"><span>Black–Scholes</span><span>continuous monitoring</span><span>reflection principle</span><span class="is-live">computed at build time</span></div>
<nav class="fc-toc">
<a href="#Prices"><b>01</b>Prices</a>
<a href="#Reflection-principle"><b>02</b>Reflection principle</a>
<a href="#Sensitivities"><b>03</b>Sensitivities</a>
<a href="#Monte-Carlo-check"><b>04</b>Monte Carlo check</a>
</nav>
</div>
```
## Prices

A barrier option is a European option that is knocked out (out) or activated (in) the first time the underlying
crosses a barrier ``H``, below the spot (down) or above it (up). The barrier is monitored continuously and there is no
rebate ([Merton](references.md#Option-pricing), [Reiner and Rubinstein](references.md#Option-pricing)). The four
functions take the arguments of [`blsprice`](@ref), with the barrier before the flag:

| Function | Barrier | The option pays the European payoff if the underlying |
|:--|:--|:--|
| [`blsdownout`](@ref) | ``H < S`` | never goes below ``H`` |
| [`blsdownin`](@ref) | ``H < S`` | goes below ``H`` at least once |
| [`blsupout`](@ref) | ``H > S`` | never goes above ``H`` |
| [`blsupin`](@ref) | ``H > S`` | goes above ``H`` at least once |

```@example barriers
using FinancialToolbox
S = 100.0; K = 100.0; r = 0.02; T = 1.0; σ = 0.2; d = 0.01
blsdownout(S, K, r, T, σ, d, 90.0), blsdownin(S, K, r, T, σ, d, 90.0)
```

```@example barriers
blsupout(S, K, r, T, σ, d, 110.0, false), blsupin(S, K, r, T, σ, d, 110.0, false)
```

Exactly one of the knock-out and the knock-in pays, so together they are the European option (in-out parity):

```@example barriers
blsdownout(S, K, r, T, σ, d, 90.0) + blsdownin(S, K, r, T, σ, d, 90.0) ≈ blsprice(S, K, r, T, σ, d)
```

![Prices and deltas of barrier options as functions of the spot](assets/figures/barriers-light.svg)![Prices and deltas of barrier options as functions of the spot](assets/figures/barriers-dark.svg)

The knock-outs vanish on the barrier, where the knock-ins become the European option. Near the barrier the delta of
a knock-out is large: the option loses all its value over a small move of the spot.

## Reflection principle

The prices are not new formulas, they are combinations of [`blsprice`](@ref) and [`blsbin`](@ref). Let ``\tilde V`` be
the European price of the payoff restricted to the side of the barrier where the option is alive. By the reflection
principle, the knock-out is

```math
V_{out}(S) = \tilde V(S) - \left(\frac{H}{S}\right)^{p} \tilde V\!\left(\frac{H^2}{S}\right), \qquad
p = \frac{2 (r - d)}{\sigma^2} - 1,
```

and the knock-in is the European option minus the knock-out. With ``A(z)`` the price of ``(S_T - K) 1_{S_T > z}``, a
call struck at ``z`` plus a binary paying ``z - K``, and ``B(z)`` the price of ``(K - S_T) 1_{S_T < z}``, a put struck
at ``z`` plus a binary paying ``K - z``:

| Option | ``\tilde V`` |
|:--|:--|
| down-and-out call | ``A(\max(K, H))`` |
| down-and-out put | ``A(\max(K, H)) - A(H)`` |
| up-and-out call | ``B(\min(K, H)) - B(H)`` |
| up-and-out put | ``B(\min(K, H))`` |

The put and the call differ by ``(S_T - K)`` restricted to the alive side (put-call parity). In the code this is a
weight of 0 or -1 from the flag, not a branch, and the position of the strike with respect to the barrier is absorbed
by `max` and `min`. So one formula covers every case, and reverse mode AD (Zygote) records no control flow. The price
is smooth at ``K = H``, where the kink of `max` is multiplied by ``\max(K, H) - K = 0``. A down-and-out put with
``K \le H`` and an up-and-out call with ``K \ge H`` are worth exactly zero: the payoff needs the barrier to be crossed.

```@example barriers
blsdownout(S, 90.0, r, T, σ, d, 95.0, false), blsupout(S, 110.0, r, T, σ, d, 105.0)
```

## Sensitivities

There are no closed form Greeks for the barrier options and no differentiation rules of their own: every AD backend
and number type differentiates through the code, down to the rules of the Black formula. Here the gradient with
respect to all the inputs, barrier included, with ForwardDiff and with Zygote:

```@example barriers
using ForwardDiff, Zygote
x = [S, K, r, T, σ, d, 90.0]
ForwardDiff.gradient(y -> blsdownout(y...), x)
```

```@example barriers
collect(Zygote.gradient((y...) -> blsdownout(y...), x...))
```

## Monte Carlo check

These closed forms are the references of the barrier options of
[FinancialMonteCarlo.jl](https://github.com/rcalxrc08/FinancialMonteCarlo.jl). A plain Monte Carlo on a time grid
monitors the barrier only at the grid points and overprices the knock-out. The probability that a Brownian bridge
crosses the barrier between two points corrects for this, and recovers continuous monitoring. The estimate and its
standard error, then the closed form:

```@example barriers
using Random
function down_and_out_monte_carlo(S, K, r, T, σ, d, H; steps = 100, paths = 100_000, rng = Xoshiro(0))
    dt = T / steps
    drift, vol, h = (r - d - σ^2 / 2) * dt, σ * sqrt(dt), log(H)
    total, total_squares = 0.0, 0.0
    for _ = 1:paths
        x, alive = log(S), 1.0
        for _ = 1:steps
            y = x + drift + vol * randn(rng)
            # probability that the bridge from x to y stays above the barrier
            alive *= y > h ? 1 - exp(-2 * (x - h) * (y - h) / vol^2) : 0.0
            x = y
        end
        payoff = alive * max(exp(x) - K, 0.0)
        total += payoff
        total_squares += abs2(payoff)
    end
    mean = total / paths
    return exp(-r * T) .* (mean, sqrt((total_squares / paths - abs2(mean)) / paths))
end
price, standard_error = down_and_out_monte_carlo(S, K, r, T, σ, d, 90.0)
price, standard_error, blsdownout(S, K, r, T, σ, d, 90.0)
```
