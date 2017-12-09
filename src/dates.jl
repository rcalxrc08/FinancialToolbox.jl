#import Base.==,Base.-,Base.+;
function dayNumber(inDate::Date)
	return Dates.date2epochdays(inDate);
end

excelcostant=693959;

"""
From Excel Number Format to Date

		Date1=fromExcelNumberToDate(ExcelNumber)

Where:\n
		ExcelNumber = Integer representing a date in the excel format.

		Date1      = Date representing the input in the Julia object format.

# Example
```julia-repl
julia> fromExcelNumberToDate(45000)
2023-03-15
```
"""
function fromExcelNumberToDate(num::Integer)
	return Dates.Dates.epochdays2date(excelcostant+num);
end

"""
Actual Number of days between two dates

		Date1=daysact(ExcelNumber)

Where:\n
		ExcelNumber = Integer representing a date in the excel format.

		Date1      = Date representing the input in the Julia object format.

# Example
```julia-repl
julia> daysact(Date(1996,10,12),Date(1998,1,10))
455
```
"""
function daysact(Data1::Date,Data2::Date)
	D1= dayNumber(Data1);
	D2= dayNumber(Data2);
	dayCount=D2-D1;
	return dayCount;
end

function isLastOfFebruary(inDate::Date)
	return (Dates.isleapyear(Dates.year(inDate))&&(Dates.day(inDate)==29)&&(Dates.month(inDate)==2))||((!Dates.isleapyear(Dates.year(inDate)))&&(Dates.day(inDate)==28)&&(Dates.month(inDate)==2));
end

currMaxImplemented=6;

"""
Fraction of year between two Dates according the following convention

		yfr=yearfrac(Date1,Date2,basis)

Where:\n
		Date1 = Start date.
		Date2 = End date.
		basis = Integer representing the following conventions:
				- 0 = (ACT/ACT)
				- 1 = (30/360 SIA)
				- 2 = (ACT/360)
				- 3 = (ACT/365)
				- 4 = (30/360 PSA)
				- 5 = (30/360 ISDA)
				- 6 = (30E/360)

		yfr      = fraction of year between start and end date according to basis.

# Example
```julia-repl
julia> yearfrac(Date(1996,10,12),Date(1998,1,10),1)
1.2444444444444445
```
"""
function yearfrac(startDate::Date,endDate::Date,convention::Integer)
if(convention>currMaxImplemented)
	error("Convention not implemented yet")
end
yearFrac=0.0;
tmpDate=1;
if (convention==0)#(ACT/ACT)
	Nday=daysact(startDate,endDate);
	EndOFYear=Date();
	if(isLastOfFebruary(startDate)&&(Dates.day(startDate)==29))
		EndOFYear=Date(Dates.year(startDate)+1,3,1);
	else
		EndOFYear=Date(Dates.year(startDate)+1,Dates.month(startDate),Dates.day(startDate));
	end
	yearFrac=(Nday)/ daysact(startDate,EndOFYear);
elseif(convention==1)  	#(30/360 SIA)
	y1=Dates.year(startDate);
	m1=Dates.month(startDate);
	y2=Dates.year(endDate);
	m2=Dates.month(endDate);
	d1=Dates.day(startDate);
	d2=Dates.day(endDate);
	if(isLastOfFebruary(startDate)&&isLastOfFebruary(endDate))
		d2=30;
	end
	if(isLastOfFebruary(startDate)||Dates.day(startDate)==31)
		d1=30;
	end
	if(d1==30&&d2==31)
		d2=30;
	end
	dy=y2-y1;
	dm=m2-m1;
	dd=d2-d1;
	yearFrac=(360.0*dy+30.0*dm+dd)/360.0;
elseif(convention==2)		#(ACT/360)
	Nday=daysact(startDate,endDate);
	yearFrac=(Nday)/360.0;
elseif(convention==3)		# (ACT/365)
	Nday=daysact(startDate,endDate);
	yearFrac=( Nday)/365.0;
elseif(convention==4)		# (30/360 PSA)
	y1=Dates.year(startDate);
	m1=Dates.month(startDate);
	y2=Dates.year(endDate);
	m2=Dates.month(endDate);
	d1=Dates.day(startDate);
	d2=Dates.day(endDate);
	if((Dates.day(startDate)==31)||isLastOfFebruary(startDate))
		d1=30;
	end
	if((Dates.day(startDate)==30||isLastOfFebruary(startDate))&&Dates.day(endDate)==31)
		d2=30;
	end
	dy=y2-y1;
	dm=m2-m1;
	dd=d2-d1;
	yearFrac=(360.0*dy+30.0*dm+dd)/360.0;

	#########
elseif(convention==5)		#(30/360 ISDA)
	y1=Dates.year(startDate);
	m1=Dates.month(startDate);
	y2=Dates.year(endDate);
	m2=Dates.month(endDate);
	if(Dates.day(startDate)<31)
		d1=Dates.day(startDate);
	else
		d1=30;
	end
	if ((Dates.day(endDate)==31)&(d1>29))
		d2=30;
	else
		d2=Dates.day(endDate);
	end
	yearFrac=(360.0*((y2-y1))+30.0*((m2-m1))+(d2-d1))/360.0;

elseif(convention==6)		#(30E/360)
	y1=Dates.year(startDate);
	m1=Dates.month(startDate);
	y2=Dates.year(endDate);
	m2=Dates.month(endDate);
	d1=Dates.day(startDate);
	d2=Dates.day(endDate);
	if(d1==31)
		d1=30;
	end
	if(d2==31)
		d2=30;
	end
	dy=y2-y1;
	dm=m2-m1;
	dd=d2-d1;
	yearFrac=(360.0*dy+30.0*dm+dd)/360.0;

	############
end
return yearFrac;

end