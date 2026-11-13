```@raw html
<div class="fc-hero">
<div class="fc-hero-text">
<p class="fc-eyebrow"><img src="assets/logo.png" alt="" width="28" height="28"> FinancialToolbox.jl</p>
```

# Black–Scholes Pricing, Greeks and Implied Volatility

```@raw html
<p class="fc-lede">Closed-form prices and sensitivities in the syntax of the Matlab Financial Toolbox, and an implied volatility accurate to machine precision: generic in the number type, so automatic differentiation, BigFloat and GPUs work out of the box.</p>
<nav class="fc-cta">
<a class="fc-btn fc-btn-primary" href="#Quick-start">Get Started <span aria-hidden="true">→</span></a>
<a class="fc-btn" href="https://github.com/rcalxrc08/FinancialToolbox.jl"><svg viewBox="0 0 16 16" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/></svg> View on GitHub</a>
</nav>
<pre class="fc-hero-code"><code><span class="k">price</span> = blsprice(S0, K, r, T, σ, d)
<span class="k">σ_imp</span> = blsimpv(S0, K, r, T, price, d)  <span class="c"># inverse</span>
<span class="k">Γ</span>     = blsgamma.(spots, K, r, T, σ, d)  <span class="c"># broadcast</span></code></pre>
</div>
<figure class="fc-hero-figure">
<img src="assets/figures/hero-surface-dark.svg" alt="Gamma of a European option across spot and maturity, computed with blsgamma">
<img src="assets/figures/hero-surface-light.svg" alt="Gamma of a European option across spot and maturity, computed with blsgamma">
<figcaption><span class="fc-legend"><i class="fc-ramp"></i>gamma of a European option, <code>blsgamma</code></span>
Computed with FinancialToolbox.jl when this site was built: one broadcast of blsgamma over 46 spots and 34 maturities.</figcaption>
</figure>
</div>
```


```@example home
Main.DocumentationFigures.hero_stats()  # hide
```

## What it does

```@raw html
<p class="fc-section-lede">Plain scalar functions without allocations: <em>generic in the number type, so the same call prices, differentiates, runs in any precision and broadcasts on a GPU</em>.</p>
<div class="fc-grid fc-features">
<article class="fc-card"><div class="fc-icon"><svg viewBox="0 0 32 32"><path d="M3 24 C9 24 10 8 16 8 S23 20 29 12"/><circle cx="16" cy="8" r="2.4"/></svg></div>
<h3>Pricing</h3><p><code>blsprice</code>, <code>blkprice</code> and <code>blsbin</code>: European and binary options in the Black–Scholes and Black models.</p><p class="fc-why">The Matlab syntax, so existing code ports line by line.</p></article>
<article class="fc-card"><div class="fc-icon"><svg viewBox="0 0 32 32"><rect x="4" y="4" width="7" height="7" rx="1.5"/><rect x="12.5" y="4" width="7" height="7" rx="1.5"/><rect x="21" y="4" width="7" height="7" rx="1.5"/><rect x="4" y="12.5" width="7" height="7" rx="1.5"/><rect x="12.5" y="12.5" width="7" height="7" rx="1.5" class="hl"/><rect x="21" y="12.5" width="7" height="7" rx="1.5"/><path d="M16 21v7"/></svg></div>
<h3>Greeks</h3><p><code>blsdelta</code>, <code>blsgamma</code>, <code>blstheta</code>, <code>blsvega</code>, <code>blsrho</code>, <code>blslambda</code>, <code>blspsi</code>, <code>blsvanna</code>.</p><p class="fc-why">Closed forms, cheaper and exact compared with differentiating the price.</p></article>
<article class="fc-card"><div class="fc-icon"><svg viewBox="0 0 32 32"><ellipse cx="16" cy="16" rx="12" ry="6"/><ellipse cx="16" cy="16" rx="7" ry="3.2"/><circle cx="16" cy="16" r="1.6" class="hl"/></svg></div>
<h3>Implied volatility</h3><p><code>blsimpv</code> and <code>blkimpv</code> on the 2024 version of Jäckel's <i>Let's Be Rational</i>: at most two Householder steps.</p><p class="fc-why">Machine precision at any moneyness, where Newton diverges.</p></article>
<article class="fc-card"><div class="fc-icon"><svg viewBox="0 0 32 32"><path d="M4 9h24M4 16h24M4 23h24"/><circle cx="10" cy="9" r="2.4"/><circle cx="20" cy="16" r="2.4"/><circle cx="14" cy="23" r="2.4"/></svg></div>
<h3>Any number type</h3><p><code>Float32</code> computed in single precision, <code>BigFloat</code> in full precision, complex numbers by analytic continuation.</p><p class="fc-why">One code path from GPU kernels to arbitrary-precision references.</p></article>
<article class="fc-card"><div class="fc-icon"><svg viewBox="0 0 32 32"><path d="M4 26 16 6l12 20z"/><path d="M10 26 16 16l6 10"/></svg></div>
<h3>Every AD backend</h3><p>ForwardDiff, ReverseDiff, Zygote, Mooncake, Enzyme, TaylorSeries, TaylorDiff, DualNumbers, HyperDualNumbers; Symbolics too.</p><p class="fc-why">Rules for <code>blsimpv</code> by the implicit function theorem, not through its iterations.</p></article>
<article class="fc-card"><div class="fc-icon"><svg viewBox="0 0 32 32"><rect x="7" y="7" width="18" height="18" rx="3"/><rect x="12" y="12" width="8" height="8" rx="1"/><path d="M11 3v4M16 3v4M21 3v4M11 25v4M16 25v4M21 25v4M3 11h4M3 16h4M3 21h4M25 11h4M25 16h4M25 21h4"/></svg></div>
<h3>GPU broadcasts</h3><p>Every function broadcasts over <code>CuArray</code>s in a single kernel, differentiated by Zygote, Mooncake, ForwardDiff and DualNumbers.</p><p class="fc-why">Calibrations over thousands of quotes without leaving the device.</p></article>
<article class="fc-card"><div class="fc-icon"><svg viewBox="0 0 32 32"><path d="M16 4v8M16 20v8M4 16h8M20 16h8"/><circle cx="16" cy="16" r="4"/></svg></div>
<h3>Calibration</h3><p>A worked calibration on the GPU, with the sensitivities of the parameters to the quoted prices.</p><p class="fc-why">The pattern FinancialCalibrator.jl builds on.</p></article>
<article class="fc-card"><div class="fc-icon"><svg viewBox="0 0 32 32"><rect x="5" y="7" width="22" height="20" rx="3"/><path d="M5 13h22M11 4v6M21 4v6"/><circle cx="16" cy="20" r="2"/></svg></div>
<h3>Dates</h3><p><code>yearfrac</code>, <code>daysact</code> and Excel date numbers.</p><p class="fc-why">The day counts a pricing library needs, in the same package.</p></article>
</div>
```

## How it fits together

```@raw html
<p class="fc-section-lede">The pricing functions go one way, the implied volatility the other; both are differentiable, so the Greeks of either come from any AD backend.</p>
<div class="fc-arch">
<ol class="fc-flow" style="--fc-steps: 6">
<li><span class="fc-node-k">01</span><b>Inputs</b><span>spot, strike, rate, maturity, volatility, dividend</span></li>
<li class="fc-core"><span class="fc-node-k">02</span><b>Black–Scholes formula</b><span><code>blsprice</code>, <code>blkprice</code>, <code>blsbin</code></span></li>
<li><span class="fc-node-k">03</span><b>Price and Greeks</b><span><code>blsdelta</code>, <code>blsvega</code>, …</span></li>
<li><span class="fc-node-k">04</span><b>Market price</b><span>a quote, a model price</span></li>
<li class="fc-core"><span class="fc-node-k">05</span><b>Implied volatility</b><span><code>blsimpv</code>, <code>blkimpv</code><br>Let's Be Rational</span></li>
<li class="fc-out"><span class="fc-node-k">06</span><b>Derivatives</b><span>AD; ∂σ/∂price = 1 / vega</span></li>
</ol>
<div class="fc-backflow"><span>∂σ/∂p</span> = <span>1 / vega(σ)</span> <em>← the rule of blsimpv: the implicit function theorem at the solution, not the iterations of the solver</em></div>
</div>
```

## Results

```@raw html
<p class="fc-section-lede">Computed with the package when this site is built.</p>
<div class="fc-tabs">
<input type="radio" name="fc-results" id="fc-results-1" checked><label for="fc-results-1">Greeks</label>
<input type="radio" name="fc-results" id="fc-results-2"><label for="fc-results-2">Accuracy</label>
<input type="radio" name="fc-results" id="fc-results-3"><label for="fc-results-3">Why not Newton</label>
<input type="radio" name="fc-results" id="fc-results-4"><label for="fc-results-4">Derivatives</label>
<div class="fc-tab-panels">
<figure class="fc-tab-panel"><img src="assets/figures/greeks-dark.svg" alt="Price and Greeks as functions of the spot"><img src="assets/figures/greeks-light.svg" alt="Price and Greeks as functions of the spot"><figcaption><b>Price and Greeks.</b> A call and a put as functions of the spot, K = 100, T = 1, σ = 20%.</figcaption></figure>
<figure class="fc-tab-panel"><img src="assets/figures/accuracy-dark.svg" alt="Error of blsimpv in Float64 against BigFloat"><img src="assets/figures/accuracy-light.svg" alt="Error of blsimpv in Float64 against BigFloat"><figcaption><b>Accuracy.</b> The implied volatility of Float64 prices against BigFloat, in units of eps(Float64), across moneyness and volatility.</figcaption></figure>
<figure class="fc-tab-panel"><img src="assets/figures/fractal-dark.svg" alt="Basins of Newton's method for the implied volatility"><img src="assets/figures/fractal-light.svg" alt="Basins of Newton's method for the implied volatility"><figcaption><b>Why not Newton.</b> The basins of Newton's method on the implied volatility: fractal, where Let's Be Rational converges from everywhere.</figcaption></figure>
<figure class="fc-tab-panel"><img src="assets/figures/impv_derivatives-dark.svg" alt="Derivatives of the implied volatility"><img src="assets/figures/impv_derivatives-light.svg" alt="Derivatives of the implied volatility"><figcaption><b>Derivatives of the implied volatility.</b> From the rules of blsimpv, see <a href="ad/">Automatic differentiation</a>.</figcaption></figure>
</div>
</div>
```

## Quick start

```@raw html
<p class="fc-section-lede">Five steps, every output computed when this site was built.</p>
```

```@raw html
<div class="fc-step"><span class="fc-step-n">1</span><div><h3>Install the package</h3><p>From the General registry.</p></div></div>
```

```julia
using Pkg
Pkg.add("FinancialToolbox")
```

```@raw html
<div class="fc-step"><span class="fc-step-n">2</span><div><h3>Price a call</h3><p>Spot, strike, rate, maturity, volatility, dividend.</p></div></div>
```

```@example quickstart
using FinancialToolbox
S0 = 100.0; K = 100.0; r = 0.02; T = 1.2; σ = 0.2; d = 0.01
price = blsprice(S0, K, r, T, σ, d)
```

```@raw html
<div class="fc-step"><span class="fc-step-n">3</span><div><h3>Back to the volatility</h3><p>The implied volatility of that price.</p></div></div>
```

```@example quickstart
blsimpv(S0, K, r, T, price, d)
```

```@raw html
<div class="fc-step"><span class="fc-step-n">4</span><div><h3>Puts and Greeks</h3><p>The last argument selects a put; the Greeks take the same arguments.</p></div></div>
```

```@example quickstart
blsprice(S0, K, r, T, σ, d, false), blsdelta(S0, K, r, T, σ, d, false), blsvega(S0, K, r, T, σ, d)
```

```@raw html
<div class="fc-step"><span class="fc-step-n">5</span><div><h3>Any precision</h3><p>Single and arbitrary precision, with the same functions.</p></div></div>
```

```@example quickstart
blsimpv(Float32.((S0, K, r, T, price, d))...), blsimpv(big.((S0, K, r, T, price, d))...)
```

```@raw html
<div class="fc-next">
<a href="pricing/"><b>Pricing and Greeks</b><span>The formulas, the Black model and binaries.</span></a>
<a href="implied_volatility/"><b>Implied volatility</b><span>Let's Be Rational, accuracy, complex numbers.</span></a>
<a href="gpu/"><b>GPU and calibration</b><span>Broadcasts, their derivatives, a calibration.</span></a>
<a href="api/"><b>API reference</b><span>Every exported function.</span></a>
</div>
```

## The ecosystem

FinancialToolbox.jl is the base of the other packages of rcalxrc08:
[FinancialMonteCarlo.jl](https://github.com/rcalxrc08/FinancialMonteCarlo.jl) and
[FinancialFFT.jl](https://github.com/rcalxrc08/FinancialFFT.jl) check their prices against it,
[FinancialCalibrator.jl](https://github.com/rcalxrc08/FinancialCalibrator.jl) calibrates on its implied volatilities,
and [VibratoMonteCarlo.jl](https://github.com/rcalxrc08/VibratoMonteCarlo.jl) on its Greeks. More projects at
[rcalxrc08.github.io](https://rcalxrc08.github.io/).
