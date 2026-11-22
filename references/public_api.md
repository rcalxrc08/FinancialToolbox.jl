# Public API

_The exported names._ (Layer 3 reference; every exported function documents all its arguments.)

| Name | Signature | Stage | Notes |
|:--|:--|:--|:--|
| `normcdf`, `normpdf` | `normcdf(x)` | 02 | standard normal |
| `blsprice` | `blsprice(S0, K, r, T, σ, d, FlagIsCall = true)` | 02 | Black–Scholes price |
| `blkprice` | `blkprice(F0, K, r, T, σ, FlagIsCall = true)` | 02 | Black price |
| `blsbin` | `blsbin(S0, K, r, T, σ, d, FlagIsCall = true)` | 02 | binary (cash-or-nothing) |
| `blsdelta`, `blsgamma`, `blsvega`, `blsrho`, `blstheta`, `blslambda`, `blspsi`, `blsvanna` | `(S0, K, r, T, σ, d, FlagIsCall = true)` | 02 | Greeks (gamma, vega, vanna ignore the flag) |
| `blsdownout`, `blsdownin`, `blsupout`, `blsupin` | `(S0, K, r, T, σ, d, H, FlagIsCall = true)` | 03 | continuous monitoring, no rebate |
| `blsimpv` | `blsimpv(S0, K, r, T, Price, d, FlagIsCall = true, xtol, ytol)` | 04 | implied volatility |
| `blkimpv` | `blkimpv(F0, K, r, T, Price, FlagIsCall = true, xtol, ytol)` | 04 | Black implied volatility |
| `yearfrac` | `yearfrac(Date1::Date, Date2::Date, basis::Integer)` | 01 | Matlab bases 0-7 |
| `daysact` | `daysact(Date1::Date, Date2::Date)` | 01 | actual days |
| `fromExcelNumberToDate` | `fromExcelNumberToDate(ExcelNumber::Integer)` | 01 | Excel serial date |

Not exported, used by the dependent packages and the extensions: `blprice_impl`, `blimpv`, `value_and_partials`,
`domain_value`, `call_put_sign`, `check_positive`, `blcheck`, `square`, `cube`. Check the exact signatures in the
docstrings (`docs/src/api.md`) before relying on this table.
