<!-- =============================
     ABOUT
    ============================== -->

\begin{section}{title="About this Package", name="About"}

\lead{FinancialToolbox.jl is a Julia package containing some useful Financial functions for Pricing and Risk Management under the Black and Scholes Model.}
The syntax is the same of the Matlab Financial Toolbox. It provides:
* **Pricing**: `blsprice`, `blkprice` (European options in the Black and Scholes and Black models), `blsbin` (binary options).
* **Sensitivities**: `blsdelta`, `blsgamma`, `blstheta`, `blsvega`, `blsrho`, `blslambda`, `blspsi`, `blsvanna`.
* **Implied volatility**: `blsimpv`, `blkimpv`, based on the 2024 version of Peter Jäckel's [Let's Be Rational](http://www.jaeckel.org/LetsBeRational.pdf): at most two Householder iterations, accurate to the attainable machine precision for any moneyness.
* **Dates**: `yearfrac`, `daysact`, `fromExcelNumberToDate`.

Every function is generic in the number type:
* `Float64`, `Float32` (computed in single precision), `BigFloat` (computed in full precision, implied volatility included) and Complex numbers (the implied volatility returns the analytic continuation of the real one).
* Automatic differentiation, forward and reverse, first and higher order (see [below](#AD)): [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl), [ReverseDiff.jl](https://github.com/JuliaDiff/ReverseDiff.jl), [Zygote.jl](https://github.com/FluxML/Zygote.jl), [Mooncake.jl](https://github.com/chalk-lab/Mooncake.jl), [Enzyme.jl](https://github.com/EnzymeAD/Enzyme.jl), [TaylorSeries.jl](https://github.com/JuliaDiff/TaylorSeries.jl), [TaylorDiff.jl](https://github.com/JuliaDiff/TaylorDiff.jl), [Dual Numbers](https://github.com/JuliaDiff/DualNumbers.jl), [HyperDual Numbers](https://github.com/JuliaDiff/HyperDualNumbers.jl).
* Symbolic computations with [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl).
\end{section}


<!-- ==============================
     GETTING STARTED
     ============================== -->
\begin{section}{title="Getting started"}


In order to get started, just add the package:

```
pkg> add FinancialToolbox
```
and load it:
```julia:ex__1
using FinancialToolbox
```
\end{section}



<!-- ==============================
     SPECIAL COMMANDS
     ============================== -->
\begin{section}{title="Example of Usage"}
* [Pricing European Options in the Black and Scholes model](#blsprice)
* [Pricing European Options in the Black model](#blkprice)
* [Implied Volatility in the Black and Scholes model](#blsimpv)
* [Implied Volatility in the Black model](#blkimpv)
\label{blsprice}
**Pricing a European Option in Black and Scholes framework**:\\ 
According to Black and Scholes model, the price of a european option can be expressed as follows:
\begin{columns}
\begin{column}{}
**_European Call Price_**
$$ C_{bs}(S,K,r,T,\sigma,d) = S e^{-d\,T} N(d_1) - Ke^{-r\,T} N(d_2) $$
\end{column}
\begin{column}{}
**_European Put Price_**
$$ P_{bs}(S,K,r,T,\sigma,d) =  Ke^{-r\,T} N(-d_2) - S e^{-d\,T} N(-d_1) $$
\end{column}
\end{columns}
where:
$$d_1 = \frac{\ln\left(\frac{S}{K}\right) + \left(r - q + \frac{\sigma^2}{2}\right) T}{\sigma\sqrt{T}}$$
$$d_2 = d_1 - \sigma\sqrt{T}$$
\\
And:
* $S$ is the underlying spot price.
* $K$ is the strike price.
* $r$ is the risk free rate.
* $T$ is the time to maturity.
* $\sigma$ is the implied volatility of the underlying.
* $d$ is the implied dividend of the underlying.
The way to compute the price in this library is:
\begin{columns}
\begin{column}{}
**_European Call Price_**
```julia:ex_7
S=100.0; K=100.0; r=0.02; T=1.2; σ=0.2; d=0.01;
Price_call=blsprice(S,K,r,T,σ,d)
```
\end{column}
\begin{column}{}
**_European Put Price_**
```julia:ex_7
S=100.0; K=100.0; r=0.02; T=1.2; σ=0.2; d=0.01;
Price_put=blsprice(S,K,r,T,σ,d,false)
```
\end{column}
\end{columns}
\\
\label{blkprice}
**Pricing a European Option in Black framework**:\\ 
According to Black model, the price of a european option can be expressed as follows:
\begin{columns}
\begin{column}{}
**_European Call Price_**
$$ C_{bk}(F,K,r,T,\sigma) = F e^{-r\,T} N(d_1) - Ke^{-r\,T} N(d_2) $$
\end{column}
\begin{column}{}
**_European Put Price_**
$$ P_{bk}(F,K,r,T,\sigma) =  Ke^{-r\,T} N(-d_2) - F e^{-r\,T} N(-d_1) $$
\end{column}
\end{columns}
where:
$$d_1 = \frac{\ln\left(\frac{F}{K}\right) + \frac{\sigma^2}{2}T}{\sigma\sqrt{T}}$$
$$d_2 = d_1 - \sigma\sqrt{T}$$
\\
And:
* $F$ is the underlying forward price.
* $K$ is the strike price.
* $r$ is the risk free rate.
* $T$ is the time to maturity.
* $\sigma$ is the implied volatility of the underlying.
The way to compute the price in this library is:
\begin{columns}
\begin{column}{}
**_European Call Price_**
```julia:ex_7
F=100.0; K=102.0; r=0.02; T=1.2; σ=0.2;
Price_call=blkprice(F,K,r,T,σ)
```
\end{column}
\begin{column}{}
**_European Put Price_**
```julia:ex_7
F=100.0; K=102.0; r=0.02; T=1.2; σ=0.2;
Price_put=blkprice(F,K,r,T,σ,false)
```
\end{column}
\end{columns}
\\
\label{blsimpv}
**Computing Implied Volatility in a Black and Scholes framework**: Given an option price $V$, the Black and Scholes implied volatility is defined as the positive number $\sigma$ which solves:
\begin{columns}
\begin{column}{}
**_From European Call Price_**
$$ V = S e^{-d\,T} N(d_1) - Ke^{-r\,T} N(d_2) $$
\end{column}
\begin{column}{}
**_From European Put Price_**
$$ V =  Ke^{-r\,T} N(-d_2) - S e^{-d\,T} N(-d_1) $$
\end{column}
\end{columns}
where:
$$d_1 = \frac{\ln\left(\frac{S}{K}\right) + \left(r - q + \frac{\sigma^2}{2}\right) T}{\sigma\sqrt{T}}$$
$$d_2 = d_1 - \sigma\sqrt{T}$$
\\
The way to compute the volatility in this library is:
\begin{columns}
\begin{column}{}
**_Implied Volatility from Call Price_**
```julia:ex_7
S=100.0; K=100.0; r=0.02; T=1.2; d=0.01;
call_price=9.169580760087896
σ=blsimpv(S,K,r,T,call_price,d)
```
\end{column}
\begin{column}{}
**_Implied Volatility from Put Price_**
```julia:ex_7
S=100.0; K=100.0; r=0.02; T=1.2; d=0.01;
put_price=7.990980449685762
σ=blsimpv(S,K,r,T,put_price,d,false)
```
\end{column}
\end{columns}
blsimpv accepts additional arguments such as the absolute tolerance and the maximum numbers of steps of the numerical inversion.
\alert{Currently blsimpv is using the rational inversion method based on [LetsBeRational](http://www.jaeckel.org/LetsBeRational.pdf) method in order to invert the relation between the price and the volatility.
If you notice something wrong with the numerical inversion, you are strongly suggested to open a issue.}
\\
\label{blkimpv}
**Computing Implied Volatility in Black framework**:\\
 Given an option price $V$, the Black implied volatility is defined as the positive number $\sigma$ which solves:
\begin{columns}
\begin{column}{}
**_From European Call Price_**
$$ V = F e^{-r\,T} N(d_1) - Ke^{-r\,T} N(d_2) $$
\end{column}
\begin{column}{}
**_From European Put Price_**
$$ V =  Ke^{-r\,T} N(-d_2) - F e^{-r\,T} N(-d_1) $$
\end{column}
\end{columns}
where:
$$d_1 = \frac{\ln\left(\frac{F}{K}\right) + \frac{\sigma^2}{2}T}{\sigma\sqrt{T}}$$
$$d_2 = d_1 - \sigma\sqrt{T}$$
\\
The way to compute the volatility in this library is:
\begin{columns}
\begin{column}{}
**_Implied Volatility from Call Price_**
```julia:ex_7
F=100.0; K=102.0; r=0.02; T=1.2;
call_price=7.659923984582901
σ=blkimpv(F,K,r,T,call_price)
```
\end{column}
\begin{column}{}
**_Implied Volatility from Put Price_**
```julia:ex_7
F=100.0; K=102.0; r=0.02; T=1.2;
put_price=9.612495404098706
σ=blkimpv(F,K,r,T,put_price,false)
```
\end{column}
\end{columns}
blkimpv accepts additional arguments such as the absolute tolerance and the maximum numbers of steps of the numerical inversion.
\alert{Currently blkimpv is using the rational inversion method based on [LetsBeRational](http://www.jaeckel.org/LetsBeRational.pdf) method in order to invert the relation between the price and the volatility.
If you notice something wrong with the numerical inversion, you are strongly suggested to open a issue.}
\end{section}

\begin{section}{title="Automatic Differentiation", name="AD"}
Pricers and sensitivities are plain Julia code, differentiable by any AD engine capable of differentiating the erfc function (rules for erfc are provided for TaylorSeries and TaylorDiff).\\
The implied volatility is never differentiated through the numerical solver: its derivatives are defined analytically, as shown below.
* **ChainRulesCore** `frule` and `rrule`, used by [Zygote.jl](https://github.com/FluxML/Zygote.jl), [ReverseDiff.jl](https://github.com/JuliaDiff/ReverseDiff.jl) and [Mooncake.jl](https://github.com/chalk-lab/Mooncake.jl) (forward and reverse mode).
* **Native rules** for [Enzyme.jl](https://github.com/EnzymeAD/Enzyme.jl) (forward, reverse and batched modes), [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl), Dual and HyperDual numbers, [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl).
* **Taylor series** of any order for [TaylorSeries.jl](https://github.com/JuliaDiff/TaylorSeries.jl) (`Taylor1`, `TaylorN` and nested) and [TaylorDiff.jl](https://github.com/JuliaDiff/TaylorDiff.jl).

In case your AD package is not supported, please open an issue.
\\
**Automatic Differentiation of Implied Volatility**: \\
In a Black and Scholes setup, let's define $f(S,K,r,T,\sigma,d)$ as follows:
\begin{columns}
\begin{column}{}
**_For European Call_**
$$ f = C_{bs}(S,K,r,T,\sigma,d) $$
\end{column}
\begin{column}{}
**_For European Put_**
$$ f = P_{bs}(S,K,r,T,\sigma,d) $$
\end{column}
\end{columns}
Let's fix a feasible option price $V$. Then we can compute the derivative of the implied volatility as follows:\\
Since $\sigma=\sigma(S,K,r,T,V,d)$ solves the inversion, then:
$$ f(S,K,r,T,\sigma(S,K,r,T,V,d),d) = V $$ <!--_-->
By differentating both sides for a generic parameter $\theta$ we get:
$$ \partial_{\theta}\sigma = \frac{\partial_{\theta}(V-f(S,K,r,T,\sigma,d))}{\partial_{\sigma}f(S,K,r,T,\sigma,d)} $$ <!--_-->
Very similar applies to Black model:
$$ \partial_{\theta}\sigma = \frac{\partial_{\theta}(V-f(F,K,r,T,\sigma))}{\partial_{\sigma}f(F,K,r,T,\sigma)} $$ <!--_-->
with:
\begin{columns}
\begin{column}{}
**_For European Call_**
$$ f = C_{bk}(F,K,r,T,\sigma) $$
\end{column}
\begin{column}{}
**_For European Put_**
$$ f = P_{bk}(F,K,r,T,\sigma) $$
\end{column}
\end{columns}
This formulation of the derivative allows to define analytically the frule and the rrule for the function blsimpv and blkimpv, without the need of differentiating the numerical solver, proving once again the superiority of automatic differentiation against numerical one.
\\
**Forward and reverse rules**: \\
Denoting by $\nu = \partial_{\sigma}f$ the vega and by $\theta$ the inputs other than the price, the tangent of the implied volatility in forward mode is:
$$ \dot{\sigma} = \frac{\dot{V} - \sum_{\theta} \partial_{\theta}f \, \dot{\theta}}{\nu} $$
while in reverse mode the adjoint $\bar{\sigma}$ is propagated to the inputs as:
$$ \bar{V} = \frac{\bar{\sigma}}{\nu}, \qquad \bar{\theta} = -\frac{\partial_{\theta}f}{\nu} \, \bar{\sigma} $$
The partial derivatives $\partial_{\theta}f$ and $\nu$ are the closed form sensitivities of the Black formula, evaluated once at the solution $\sigma$: a gradient costs little more than the implied volatility itself (see the [performance](#Performance) section).
\\
**Taylor series of any order**: \\
For a truncated Taylor series in the inputs (TaylorSeries.jl, TaylorDiff.jl), $\sigma$ is the solution of $f(\sigma) = V$ in the algebra of truncated series. Starting from $\sigma_0$, the implied volatility of the constant terms, Newton's method on the whole series
$$ \sigma_{m+1} = \sigma_m + \frac{V - f(\sigma_m)}{\partial_{\sigma}f(\sigma_m)} $$
is exact, not an approximation: the error of $\sigma_0$ is $O(t)$ and each step squares it, so after $m$ steps it is $O(t^{2^m})$. Hence $\lceil \log_2(n+1) \rceil$ steps give all the coefficients of a series of order $n$.
\\
**Complex numbers**: \\
The equation $f(\sigma) = V$ has many complex solutions; the same Newton iteration in the complex plane, started from the implied volatility of the real parts, returns the analytic continuation of the real implied volatility (the one needed by the complex step method).
\end{section}

<!-- ==============================
     PERFORMANCE
     ============================== -->
\begin{section}{title="Performance", name="Performance"}
Time to compute the price and the implied volatility, and their gradients with respect to all the inputs with a forward (TaylorSeries, order one TaylorN in the six inputs) and a reverse (Mooncake) mode AD library. The table is generated when this page is built.
```julia:performance
# hideall
using FinancialToolbox, BenchmarkTools, Mooncake, TaylorSeries, Printf, Logging
S0 = 100.0; K = 100.0; r = 0.02; T = 1.2; σ = 0.2; d = 0.01
price = blsprice(S0, K, r, T, σ, d)
# TaylorN variables of order 1: the gradient is in the first order coefficients (set_variables before TaylorSeries 0.23)
taylorn_variables(names; order) = isdefined(TaylorSeries, :variables!) ? TaylorSeries.variables!(names; order = order) : TaylorSeries.set_variables(names; order = order)
dx = with_logger(NullLogger()) do
    taylorn_variables("x1 x2 x3 x4 x5 x6", order = 1)
end
format_time(t) = t < 1e-6 ? @sprintf("%.0f ns", 1e9 * t) : t < 1e-3 ? @sprintf("%.2f μs", 1e6 * t) : @sprintf("%.2f ms", 1e3 * t)
function performance_row(name, f, args)
    t = @belapsed $f($(args)...)
    x_taylor = args .+ dx
    t_taylor = @belapsed $f($(x_taylor)...)
    cache = Mooncake.prepare_gradient_cache(f, args...)
    t_mooncake = @belapsed Mooncake.value_and_gradient!!($cache, $f, $(args)...)
    # both gradients agree
    g_taylor = [TaylorSeries.getcoeff(f(x_taylor...), [i == j ? 1 : 0 for j in 1:6]) for i in 1:6]
    g_mooncake = collect(Mooncake.value_and_gradient!!(cache, f, args...)[2][2:end])
    @assert isapprox(g_taylor, g_mooncake; rtol = 1e-8)
    @printf("| `%s` | %s | %s (%.1f×) | %s (%.1f×) |\n", name, format_time(t), format_time(t_taylor), t_taylor / t, format_time(t_mooncake), t_mooncake / t)
end
println("| Function | Value (Float64) | Gradient, TaylorSeries (TaylorN) | Gradient, Mooncake (reverse mode) |")
println("|:--|--:|--:|--:|")
performance_row("blsprice(S0, K, r, T, σ, d)", blsprice, (S0, K, r, T, σ, d))
performance_row("blsimpv(S0, K, r, T, price, d)", blsimpv, (S0, K, r, T, price, d))
println()
@printf("Julia %s, %s, FinancialToolbox %s; minimum time over the BenchmarkTools samples, in brackets the ratio to the value.\n", VERSION, Sys.cpu_info()[1].model, pkgversion(FinancialToolbox))
```
\textoutput{performance}
\end{section}