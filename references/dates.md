# Stage 01: dates

_Facts the day counts rely on._ (Layer 3 reference.)

- `yearfrac(Date1, Date2, basis)` follows the Matlab bases 0-7; `daysact` the actual days; `fromExcelNumberToDate` the
  Excel serial dates (`EXCEL_EPOCH`).
- Day counts in integer arithmetic, one division at the end.
- One small function per 30/360 convention: they differ only by the adjustment of the days.
- Equal dates return 0 before any convention (30/360 PSA would not).
- Reference values: Matlab (`test/core/dates.jl`).
