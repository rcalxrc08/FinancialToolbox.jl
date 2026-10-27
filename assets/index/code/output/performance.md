| Function | Value (Float64) | Gradient, TaylorSeries (TaylorN) | Gradient, Mooncake (reverse mode) |
|:--|--:|--:|--:|
| `blsprice(S0, K, r, T, σ, d)` | 32 ns | 2.91 μs (91.2×) | 112 ns (3.5×) |
| `blsimpv(S0, K, r, T, price, d)` | 157 ns | 4.57 μs (29.1×) | 270 ns (1.7×) |

Julia 1.13.3, AMD EPYC 9V45 96-Core Processor, FinancialToolbox 0.7.1; minimum time over the BenchmarkTools samples, in brackets the ratio to the value.
