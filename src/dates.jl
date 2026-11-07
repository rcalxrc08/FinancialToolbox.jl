
function dayNumber(inDate::Date)
    return Dates.date2epochdays(inDate)::Integer
end

const excelcostant = 693959

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
function fromExcelNumberToDate(num::Integer)::Date
    return Dates.Dates.epochdays2date(excelcostant + num)
end

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
function daysact(Date1::Date, Date2::Date)::Integer
    D1 = dayNumber(Date1)
    D2 = dayNumber(Date2)
    dayCount = D2 - D1
    return dayCount
end

function isLastOfFebruary(inDate::Date)::Bool
    return (Dates.isleapyear(Dates.year(inDate)) && (Dates.day(inDate) == 29) && (Dates.month(inDate) == 2)) || ((!Dates.isleapyear(Dates.year(inDate))) && (Dates.day(inDate) == 28) && (Dates.month(inDate) == 2))
end

const currMaxImplemented = 7

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
function yearfrac(startDate::Date, endDate::Date, convention::Integer)::Real
    if (convention < 0)
        error("Negative basis are not defined, check the help")
    end
    if (convention > currMaxImplemented)
        error("Convention not implemented yet")
    end
    if (startDate > endDate)
        return -yearfrac(endDate, startDate, convention)
    elseif (startDate == endDate)
        return 0.0
    end
    yearFrac = 0.0
    y1 = Dates.year(startDate)
    m1 = Dates.month(startDate)
    y2 = Dates.year(endDate)
    m2 = Dates.month(endDate)
    d1 = Dates.day(startDate)
    d2 = Dates.day(endDate)
    if (convention == 0)#(ACT/ACT)
        Nday = daysact(startDate, endDate)
        EndOFYear = Date(1)
        if (isLastOfFebruary(startDate) && (Dates.day(startDate) == 29))
            EndOFYear = Date(Dates.year(startDate) + 1, 3, 1)
        else
            EndOFYear = Date(Dates.year(startDate) + 1, Dates.month(startDate), Dates.day(startDate))
        end
        yearFrac = (Nday) / daysact(startDate, EndOFYear)
    elseif (convention == 1)  #(30/360 SIA)
        if (isLastOfFebruary(startDate) && isLastOfFebruary(endDate))
            d2 = 30
        end
        if (isLastOfFebruary(startDate) || Dates.day(startDate) == 31)
            d1 = 30
        end
        if (d1 == 30 && d2 == 31)
            d2 = 30
        end
        dy = y2 - y1
        dm = m2 - m1
        dd = d2 - d1
        yearFrac = (360.0 * dy + 30.0 * dm + dd) / 360.0
    elseif (convention == 2)#(ACT/360)
        Nday = daysact(startDate, endDate)
        yearFrac = (Nday) / 360.0
    elseif (convention == 3)# (ACT/365)
        Nday = daysact(startDate, endDate)
        yearFrac = (Nday) / 365.0
    elseif (convention == 4)# (30/360 PSA)
        if ((Dates.day(startDate) == 31) || isLastOfFebruary(startDate))
            d1 = 30
        end
        if ((Dates.day(startDate) == 30 || isLastOfFebruary(startDate)) && Dates.day(endDate) == 31)
            d2 = 30
        end
        dy = y2 - y1
        dm = m2 - m1
        dd = d2 - d1
        yearFrac = (360.0 * dy + 30.0 * dm + dd) / 360.0

    elseif (convention == 5)#(30/360 ISDA)
        y1 = Dates.year(startDate)
        m1 = Dates.month(startDate)
        y2 = Dates.year(endDate)
        m2 = Dates.month(endDate)
        if (Dates.day(startDate) < 31)
            d1 = Dates.day(startDate)
        else
            d1 = 30
        end
        if ((Dates.day(endDate) == 31) && (d1 > 29))
            d2 = 30
        else
            d2 = Dates.day(endDate)
        end
        yearFrac = (360.0 * ((y2 - y1)) + 30.0 * ((m2 - m1)) + (d2 - d1)) / 360.0

    elseif (convention == 6)#(30E/360)
        if (d1 == 31)
            d1 = 30
        end
        if (d2 == 31)
            d2 = 30
        end
        dy = y2 - y1
        dm = m2 - m1
        dd = d2 - d1
        yearFrac = (360.0 * dy + 30.0 * dm + dd) / 360.0
    elseif (convention == 7)#(ACT/365 JPN)
        daydistance = [0; 31; 59; 90; 120; 151; 181; 212; 243; 273; 304; 334]
        dy = y2 - y1
        dd = d2 - d1
        dayCount = (365.0 * dy + daydistance[m2] - daydistance[m1] + dd)
        yearFrac = dayCount / 365.0
    end

    return yearFrac
end
