```@raw html
<div class="fc-page-head">
<p class="fc-kicker"><span>Guide 06</span> Year fractions and day counts</p>
```

# Dates

Day counts with the conventions of the Matlab Financial Toolbox, on the `Date` type of the standard library Dates.

```@raw html
<div class="fc-meta"><span>yearfrac</span><span>daysact</span><span>Excel</span></div>
</div>
```

```@example dates
using FinancialToolbox, Dates
start, stop = Date(1996, 10, 12), Date(1998, 1, 10)
daysact(start, stop)
```

[`yearfrac`](@ref) takes the convention as an integer `basis`, from 0 to 7:

```@example dates
conventions = ["ACT/ACT", "30/360 SIA", "ACT/360", "ACT/365", "30/360 PSA", "30/360 ISDA", "30E/360", "ACT/365 JPN"]
[conventions[basis + 1] => yearfrac(start, stop, basis) for basis in 0:7]
```

Excel stores dates as serial numbers, converted by [`fromExcelNumberToDate`](@ref):

```@example dates
fromExcelNumberToDate(45000)
```
