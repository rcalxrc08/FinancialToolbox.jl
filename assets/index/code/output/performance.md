| Function | Value (Float64) | Gradient, TaylorSeries (TaylorN) | Gradient, Mooncake (reverse mode) |
|:--|--:|--:|--:|
| `blsprice(S0, K, r, T, σ, d)` | 44 ns | 4.35 μs (97.7×) | 167 ns (3.7×) |
| `blsimpv(S0, K, r, T, price, d)` | 209 ns | 6.77 μs (32.4×) | 353 ns (1.7×) |

Julia 1.13.3, AMD EPYC 9V74 80-Core Processor, FinancialToolbox 0.7.1; minimum time over the BenchmarkTools samples, in brackets the ratio to the value.
