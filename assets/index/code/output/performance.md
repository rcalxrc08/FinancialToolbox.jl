| Function | Value (Float64) | Gradient, TaylorSeries (TaylorN) | Gradient, Mooncake (reverse mode) |
|:--|--:|--:|--:|
| `blsprice(S0, K, r, T, σ, d)` | 55 ns | 5.59 μs (101.6×) | 199 ns (3.6×) |
| `blsimpv(S0, K, r, T, price, d)` | 245 ns | 8.41 μs (34.3×) | 417 ns (1.7×) |

Julia 1.13.3, AMD EPYC 7763 64-Core Processor, FinancialToolbox 0.8.0; minimum time over the BenchmarkTools samples, in brackets the ratio to the value.
