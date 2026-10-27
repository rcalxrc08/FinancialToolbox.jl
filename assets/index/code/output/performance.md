| Function | Value (Float64) | Gradient, TaylorSeries (TaylorN) | Gradient, Mooncake (reverse mode) |
|:--|--:|--:|--:|
| `blsprice(S0, K, r, T, σ, d)` | 54 ns | 5.50 μs (101.8×) | 204 ns (3.8×) |
| `blsimpv(S0, K, r, T, price, d)` | 242 ns | 8.58 μs (35.4×) | 415 ns (1.7×) |

Julia 1.13.3, AMD EPYC 7763 64-Core Processor, FinancialToolbox 0.8.0; minimum time over the BenchmarkTools samples, in brackets the ratio to the value.
