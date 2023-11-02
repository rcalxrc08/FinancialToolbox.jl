<!-- =============================
     ABOUT
    ============================== -->

\begin{section}{title="About this Package", name="About"}

\lead{FinancialToolbox.jl is a Julia package containing some useful Financial functions for Pricing and Risk Management under the Black and Scholes Model.}
The syntax is the same of the Matlab Financial Toolbox.
Currently supports classical numerical input and other less common like:
* Complex Numbers
* [Dual Numbers](https://github.com/JuliaDiff/DualNumbers.jl)
* [HyperDual Numbers](https://github.com/JuliaDiff/HyperDualNumbers.jl)
* [TaylorSeries.jl](https://github.com/JuliaDiff/TaylorSeries.jl)
* [TaylorDiff.jl](https://github.com/JuliaDiff/TaylorDiff.jl)
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
Price_call=blkprice(S,K,r,T,σ)
```
\end{column}
\begin{column}{}
**_European Put Price_**
```julia:ex_7
F=100.0; K=102.0; r=0.02; T=1.2; σ=0.2;
Price_put=blkprice(S,K,r,T,σ,false)
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
\alert{Currently blsimpv is using the Newton method in order to invert the relation between the price and the volatility.
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
S=100.0; K=102.0; r=0.02; T=1.2;
call_price=7.659923984582901
σ=blkimpv(S,K,r,T,call_price)
```
\end{column}
\begin{column}{}
**_Implied Volatility from Put Price_**
```julia:ex_7
S=100.0; K=102.0; r=0.02; T=1.2;
put_price=9.612495404098706
σ=blkimpv(S,K,r,T,put_price,false)
```
\end{column}
\end{columns}
blkimpv accepts additional arguments such as the absolute tolerance and the maximum numbers of steps of the numerical inversion.
\alert{Currently blkimpv is using the Newton method in order to invert the relation between the price and the volatility.
If you notice something wrong with the numerical inversion, you are strongly suggested to open a issue.}
\end{section}

\begin{section}{title="Automatic Differentiation", name="AD"}
Pricers and sensitivities functions are differentiable as far as the AD engine is capable of differentiating the erfc function.\\
Implied volatility computations are fully differentiable by using ChainRulesCore.jl.
Explicit support for ForwardDiff, ReverseDiff, TaylorDiff, TaylorSeries is added.
In case your package does not support ChainRulesCore.jl APIs, please open an issue if you need the support for implied volatility differentiation.
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
\end{section}