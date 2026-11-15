# Day counts with the conventions of the Matlab Financial Toolbox. Integer arithmetic on the day counts (exact), one
# division at the end: every year fraction is a Float64.

# Day 0 of the Excel date system (Windows), December 30, 1899, in the epoch days of Dates
const EXCEL_EPOCH = 693959

"""
    fromExcelNumberToDate(ExcelNumber::Integer)

The `Date` of an Excel serial date number.

# Arguments
- `ExcelNumber`: number of days since December 30, 1899, the date system of Excel on Windows (45000 is
  March 15, 2023).

# Example
```jldoctest
julia> fromExcelNumberToDate(45000)
2023-03-15
```
"""
fromExcelNumberToDate(ExcelNumber::Integer) = Dates.epochdays2date(EXCEL_EPOCH + ExcelNumber)

"""
    daysact(Date1::Date, Date2::Date)

Actual number of days from `Date1` to `Date2`, negative if `Date2` comes first.

# Arguments
- `Date1`: start date.
- `Date2`: end date.

# Example
```jldoctest
julia> using Dates

julia> daysact(Date(1996, 10, 12), Date(1998, 1, 10))
455
```
"""
daysact(Date1::Date, Date2::Date) = Dates.value(Date2 - Date1)

is_last_of_february(date::Date) = Dates.month(date) == 2 && Dates.day(date) == Dates.daysinmonth(date)

# Days between (y1, m1, d1) and (y2, m2, d2) with months of 30 days and years of 360
days_30_360(y1, m1, d1, y2, m2, d2) = 360 * (y2 - y1) + 30 * (m2 - m1) + (d2 - d1)

# Days of a non-leap year before the first of each month (ACT/365 JPN ignores February 29)
const DAYS_BEFORE_MONTH = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)

# ACT/ACT: actual days over the days of the year starting at the start date (February 29 to March 1)
function year_fraction_act_act(startDate::Date, endDate::Date)
    y1, m1, d1 = Dates.yearmonthday(startDate)
    anniversary = m1 == 2 && d1 == 29 ? Date(y1 + 1, 3, 1) : Date(y1 + 1, m1, d1)
    return daysact(startDate, endDate) / daysact(startDate, anniversary)
end

# The 30/360 conventions differ only by the adjustment of the days of the month
function days_30_360_sia(startDate::Date, endDate::Date)
    y1, m1, d1 = Dates.yearmonthday(startDate)
    y2, m2, d2 = Dates.yearmonthday(endDate)
    start_last_of_february = is_last_of_february(startDate)
    if start_last_of_february && is_last_of_february(endDate)
        d2 = 30
    end
    if start_last_of_february || d1 == 31
        d1 = 30
    end
    if d1 == 30 && d2 == 31
        d2 = 30
    end
    return days_30_360(y1, m1, d1, y2, m2, d2)
end
function days_30_360_psa(startDate::Date, endDate::Date)
    y1, m1, d1 = Dates.yearmonthday(startDate)
    y2, m2, d2 = Dates.yearmonthday(endDate)
    start_last_of_february = is_last_of_february(startDate)
    # the end of the month is checked on the day of the start date before its adjustment
    if (d1 == 30 || start_last_of_february) && d2 == 31
        d2 = 30
    end
    if d1 == 31 || start_last_of_february
        d1 = 30
    end
    return days_30_360(y1, m1, d1, y2, m2, d2)
end
function days_30_360_isda(startDate::Date, endDate::Date)
    y1, m1, d1 = Dates.yearmonthday(startDate)
    y2, m2, d2 = Dates.yearmonthday(endDate)
    d1 = min(d1, 30)
    if d2 == 31 && d1 > 29
        d2 = 30
    end
    return days_30_360(y1, m1, d1, y2, m2, d2)
end
function days_30e_360(startDate::Date, endDate::Date)
    y1, m1, d1 = Dates.yearmonthday(startDate)
    y2, m2, d2 = Dates.yearmonthday(endDate)
    return days_30_360(y1, m1, min(d1, 30), y2, m2, min(d2, 30))
end
function days_act_365_jpn(startDate::Date, endDate::Date)
    y1, m1, d1 = Dates.yearmonthday(startDate)
    y2, m2, d2 = Dates.yearmonthday(endDate)
    return 365 * (y2 - y1) + DAYS_BEFORE_MONTH[m2] - DAYS_BEFORE_MONTH[m1] + (d2 - d1)
end

const YEARFRAC_MAX_BASIS = 7

"""
    yearfrac(Date1::Date, Date2::Date, basis::Integer)

Fraction of year from `Date1` to `Date2` with the day count convention `basis`, as in Matlab:

| `basis` | Convention |
|:--|:--|
| 0 | ACT/ACT |
| 1 | 30/360 SIA |
| 2 | ACT/360 |
| 3 | ACT/365 |
| 4 | 30/360 PSA |
| 5 | 30/360 ISDA |
| 6 | 30E/360 |
| 7 | ACT/365 JPN |

# Arguments
- `Date1`: start date.
- `Date2`: end date. If it comes before `Date1`, the result is negative.
- `basis`: day count convention, an integer from 0 to 7 (see the table above).

# Example
```jldoctest
julia> using Dates

julia> yearfrac(Date(1996, 10, 12), Date(1998, 1, 10), 1)
1.2444444444444445
```
"""
function yearfrac(Date1::Date, Date2::Date, basis::Integer)
    basis < 0 && error("Negative basis are not defined, check the help")
    basis > YEARFRAC_MAX_BASIS && error("Convention not implemented yet")
    if Date1 > Date2
        return -yearfrac(Date2, Date1, basis)
    end
    # zero for every convention (30/360 PSA would adjust the two days of the same date differently)
    Date1 == Date2 && return 0.0
    basis == 0 && return year_fraction_act_act(Date1, Date2)
    basis == 1 && return days_30_360_sia(Date1, Date2) / 360
    basis == 2 && return daysact(Date1, Date2) / 360
    basis == 3 && return daysact(Date1, Date2) / 365
    basis == 4 && return days_30_360_psa(Date1, Date2) / 360
    basis == 5 && return days_30_360_isda(Date1, Date2) / 360
    basis == 6 && return days_30e_360(Date1, Date2) / 360
    return days_act_365_jpn(Date1, Date2) / 365
end
