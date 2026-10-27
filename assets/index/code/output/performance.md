| Function | Value (Float64) | Gradient, TaylorSeries (TaylorN) | Gradient, Mooncake (reverse mode) |
|:--|--:|--:|--:|
| `blsprice(S0, K, r, T, σ, d)` | 54 ns | 5.11 μs (94.2×) | 233 ns (4.3×) |
| `blsimpv(S0, K, r, T, price, d)` | 230 ns | 8.25 μs (35.9×) | 402 ns (1.7×) |

Julia 1.13.3, Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz, FinancialToolbox 0.7.1; minimum time over the BenchmarkTools samples, in brackets the ratio to the value.
