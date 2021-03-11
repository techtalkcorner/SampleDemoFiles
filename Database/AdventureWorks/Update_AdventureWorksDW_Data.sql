/* 

Description: 

---------- The script updates the date colums for the AdventureWorksDW database with recent dates and it inserts new dates in the date dimension. 

---------- It uses the current year as the last year for the data in the Adventure Works database. 

---------- AdventureWorksDW original database contains data from 2010 to 2014, ths script will update the data to be (current year - 4 yars) to current year 

---------- The script deletes leap year records from FactCurrencyRate and FactProductInventory to avoid having constraint issues

---------- For example: if the current year is 2021, the data after running the script will be from 2017 to 2021. 

 

Author: 

---------- David Alzamendi (https://techtalkcorner.com) 

 

Date: 

---------- 19/11/2020 

*/ 

 

-- Declare variables  

declare @CurrentYear int = year(getdate()) 

declare @LastDayCurrentYear date = DATEADD (dd, -1, DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) +1, 0)) 

declare @MaxDateInDW int 

select @MaxDateInDW  = MAX(year(orderdate)) from [dbo].[FactInternetSales] 

declare @YearsToAdd int = @CurrentYear - @MaxDateInDW 

 

if (@YearsToAdd>0) 

begin 

-- Delete leap year records (February 29)
delete from FactCurrencyRate where month([Date]) = 2 and day([Date]) = 29
delete from FactProductInventory  where month([MovementDate]) = 2 and day([MovementDate]) = 29


-- Drop foreign keys 

alter table FactCurrencyRate drop constraint FK_FactCurrencyRate_DimDate 

alter table FactFinance drop constraint FK_FactFinance_DimDate 

alter table FactInternetSales drop constraint FK_FactInternetSales_DimDate 

alter table FactInternetSales drop constraint FK_FactInternetSales_DimDate1 

alter table FactInternetSales drop constraint FK_FactInternetSales_DimDate2 

alter table FactProductInventory drop constraint FK_FactProductInventory_DimDate 

alter table FactResellerSales drop constraint FK_FactResellerSales_DimDate 

alter table FactSurveyResponse drop constraint FK_FactSurveyResponse_DateKey 

-- Include more dates in Date dimension, the existing dates are not being replaced 

-------------------------------------- 

--Populates the date dimension 

------------------------------------- 

DECLARE @startdate DATE = '2015-01-01' --change start date if required 

   ,@enddate   DATE = @LastDayCurrentYear --change end date if required 

        

DECLARE @datelist TABLE (FullDate DATE)  

 

--recursive date query 

;WITH dt_cte  

AS  

(  

SELECT @startdate AS FullDate  

UNION ALL  

SELECT DATEADD(DAY,1,FullDate) AS FullDate  

FROM dt_cte  

WHERE dt_cte.FullDate < @enddate  

)  

INSERT INTO @datelist 

SELECT FullDate FROM dt_cte  

OPTION (MAXRECURSION 0)  

 

--Populate Date Dimension 

SET DATEFIRST 7; -- Set the first day of the week to Monday 

 

INSERT INTO [dbo].[dimdate] 

( [DateKey] 

  ,[FullDateAlternateKey] 

  ,[DayNumberOfWeek] 

  ,[EnglishDayNameOfWeek] 

  ,[SpanishDayNameOfWeek] 

  ,[FrenchDayNameOfWeek] 

  ,[DayNumberOfMonth] 

  ,[DayNumberOfYear] 

  ,[WeekNumberOfYear] 

  ,[EnglishMonthName] 

  ,[SpanishMonthName] 

  ,[FrenchMonthName] 

  ,[MonthNumberOfYear] 

  ,[CalendarQuarter] 

  ,[CalendarYear] 

  ,[CalendarSemester] 

  ,[FiscalQuarter] 

  ,[FiscalYear] 

  ,[FiscalSemester] 

 

) 

SELECT CONVERT(INT,CONVERT(VARCHAR,dl.FullDate,112)) as DateKey 

   ,dl.FullDate 

,DATEPART(dw,dl.FullDate) as DayOfWeekNumber 

   ,DATENAME(weekday,dl.FullDate) as DayOfWeekName 

   ,case DATENAME(weekday,dl.FullDate)  

   when 'Monday' then 'Lunes'  

   when 'Tuesday' then 'Martes'  

   when 'Wednesday' then 'Miércoles'  

   when 'Thursday' then 'Jueves'  

   when 'Friday' then 'Viernes'  

   when 'Saturday' then 'Sábado'  

   when 'Sunday' then 'Doming'  

end as SpanishDayNameOfWeek 

 ,case DATENAME(weekday,dl.FullDate)  

   when 'Monday' then 'Lundi'  

   when 'Tuesday' then 'Mardi'  

   when 'Wednesday' then 'Mercredi'  

   when 'Thursday' then 'Jeudi'  

   when 'Friday' then 'Vendredi'  

   when 'Saturday' then 'Samedi'  

   when 'Sunday' then 'Dimanche'  

end as SpanishDayNameOfWeek 

   ,DATEPART(d,dl.FullDate) as DayOfMonthNumber 

   ,DATEPART(dy,dl.FullDate) as DayOfYearNumber 

   ,DATEPART(wk, dl.FullDate) as WeekOfYearNumber 

   ,DATENAME(MONTH,dl.FullDate) as [MonthName] 

,case DATENAME(MONTH,dl.FullDate) 

   when 'January' then 'Enero'  

   when 'February' then 'Febrero'  

   when 'March' then 'Marzo'  

   when 'April' then 'Abril'  

   when 'May' then 'Mayo'  

   when 'June' then 'Junio'  

   when 'July' then 'Julio'  

   when 'August' then 'Agosto'  

   when 'September' then 'Septiembre'  

   when 'October' then 'Octubre'  

   when 'November' then 'Noviembre'  

   when 'December' then 'Diciembre'  

end as SpanishMonthName 

 

  ,case DATENAME(MONTH,dl.FullDate) 

   when 'January' then 'Janvier'  

   when 'February' then 'Février'  

   when 'March' then 'Mars'  

   when 'April' then 'Avril'  

   when 'May' then 'Mai'  

   when 'June' then 'Juin'  

   when 'July' then 'Juillet'  

   when 'August' then 'Août'  

   when 'September' then 'Septembre'  

   when 'October' then 'Octobre'  

   when 'November' then 'Novembre'  

   when 'December' then 'Décembre'  

end as FrenchMonthName 

 

   ,MONTH(dl.FullDate) as MonthNumber 

   ,DATEPART(qq, dl.FullDate) as CalendarQuarter 

   ,YEAR(dl.FullDate) as CalendarYear 

   ,CASE DATEPART(qq, dl.FullDate)  

  WHEN 1 THEN 1  

  WHEN 2 THEN 1  

  WHEN 3 THEN 2  

  WHEN 4 THEN 2  

END AS CalendarSemester 

   ,CASE DATEPART(qq, dl.FullDate)  

  WHEN 1 THEN 3  

  WHEN 2 THEN 4  

  WHEN 3 THEN 1  

  WHEN 4 THEN 2  

END as FiscalQuarter 

    

   ,CASE DATEPART(qq, dl.FullDate)  

  WHEN 1 THEN YEAR(dl.FullDate) -1 

  WHEN 2 THEN YEAR(dl.FullDate) -1 

  WHEN 3 THEN YEAR(dl.FullDate)  

  WHEN 4 THEN YEAR(dl.FullDate)  

END as FiscalYear 

,CASE DATEPART(qq, dl.FullDate)  

  WHEN 1 THEN 2  

  WHEN 2 THEN 2  

  WHEN 3 THEN 1  

  WHEN 4 THEN 1  

END as FiscalSemester 

    

FROM   @datelist dl  

LEFT JOIN [dbo].[dimdate] dt  

ON dt.FullDateAlternateKey = dl.FullDate 

WHERE  dt.DateKey IS NULL 

ORDER BY DateKey DESC  

 

 

-- Date (data type: date) 

-- Birth Date and Hire Date are not being updated 

update DimCustomer set DateFirstPurchase = case when DateFirstPurchase is not null then dateadd(year,@YearsToAdd,DateFirstPurchase) end 

update DimEmployee set StartDate = case when StartDate is not null then dateadd(year,@YearsToAdd,StartDate) end 

update DimEmployee set EndDate = case when EndDate is not null then dateadd(year,@YearsToAdd,EndDate) end 

update DimProduct set StartDate = case when StartDate is not null then dateadd(year,@YearsToAdd,StartDate) end 

update DimProduct set EndDate = case when EndDate is not null then dateadd(year,@YearsToAdd,EndDate) end 

update DimPromotion set StartDate = case when StartDate is not null then dateadd(year,@YearsToAdd,StartDate) end 

update DimPromotion set EndDate = case when EndDate is not null then dateadd(year,@YearsToAdd,EndDate) end 

update FactCallCenter set Date = case when Date is not null then dateadd(year,@YearsToAdd,Date) end 

update FactCurrencyRate set Date = case when Date is not null then dateadd(year,@YearsToAdd,Date) end 

update FactFinance set Date = case when Date is not null then dateadd(year,@YearsToAdd,Date) end 

update FactInternetSales set OrderDate = case when OrderDate is not null then dateadd(year,@YearsToAdd,OrderDate) end 

update FactInternetSales set DueDate = case when DueDate is not null then dateadd(year,@YearsToAdd,DueDate) end 

update FactInternetSales set ShipDate = case when ShipDate is not null then dateadd(year,@YearsToAdd,ShipDate) end 

update FactProductInventory set MovementDate = case when MovementDate is not null then dateadd(year,@YearsToAdd,MovementDate) end 

update FactResellerSales set OrderDate = case when OrderDate is not null then dateadd(year,@YearsToAdd,OrderDate) end 

update FactResellerSales set DueDate = case when DueDate is not null then dateadd(year,@YearsToAdd,DueDate) end 

update FactResellerSales set ShipDate = case when ShipDate is not null then dateadd(year,@YearsToAdd,ShipDate) end 

update FactSalesQuota set Date = case when Date is not null then dateadd(year,@YearsToAdd,Date) end 

update FactSurveyResponse set Date = case when Date is not null then dateadd(year,@YearsToAdd,Date) end 

 

-- DateKey (data type: int) 

update FactCallCenter set DateKey = case when DateKey is not null then CAST(convert(varchar,[Date],112) as int) end 

update FactCurrencyRate set DateKey = case when DateKey is not null then CAST(convert(varchar,[Date],112) as int) end 

update FactFinance set DateKey = case when DateKey is not null then CAST(convert(varchar,[Date],112) as int) end 

update FactInternetSales set DueDateKey = case when DueDateKey is not null then CAST(convert(varchar,[DueDate],112) as int) end 

update FactInternetSales set OrderDateKey = case when OrderDateKey is not null then CAST(convert(varchar,[OrderDate],112) as int) end 

update FactInternetSales set ShipDateKey = case when ShipDateKey is not null then CAST(convert(varchar,[ShipDate],112) as int) end 

update FactProductInventory set DateKey = case when DateKey is not null then CAST(convert(varchar,[MovementDate],112) as int) end 

update FactResellerSales set DueDateKey = case when DueDateKey is not null then CAST(convert(varchar,[ShipDate],112) as int) end 

update FactResellerSales set OrderDateKey = case when OrderDateKey is not null then CAST(convert(varchar,[ShipDate],112) as int) end 

update FactResellerSales set ShipDateKey = case when ShipDateKey is not null then CAST(convert(varchar,[ShipDate],112) as int) end 

update FactSalesQuota set DateKey = case when DateKey is not null then CAST(convert(varchar,[Date],112) as int) end 

update FactSurveyResponse set DateKey = case when DateKey is not null then CAST(convert(varchar,[Date],112) as int) end 

 

-- Update tables where year is a number in the format YYYY 

update FactSalesQuota set CalendarYear = case when CalendarYear is not null then @YearsToAdd + CalendarYear end 

update DimReseller set FirstOrderYear = case when FirstOrderYear is not null then @YearsToAdd + FirstOrderYear end 

update DimReseller set LastOrderYear = case when LastOrderYear is not null then @YearsToAdd + LastOrderYear end 

update DimReseller set YearOpened = case when YearOpened is not null then @YearsToAdd + YearOpened end 

 
-- Add back CONSTRAINTS

ALTER TABLE [dbo].[FactCurrencyRate]  WITH CHECK ADD  CONSTRAINT [FK_FactCurrencyRate_DimDate] FOREIGN KEY([DateKey])
REFERENCES [dbo].[DimDate] ([DateKey])

ALTER TABLE [dbo].[FactCurrencyRate] CHECK CONSTRAINT [FK_FactCurrencyRate_DimDate]

ALTER TABLE [dbo].[FactFinance]  WITH CHECK ADD  CONSTRAINT [FK_FactFinance_DimDate] FOREIGN KEY([DateKey])
REFERENCES [dbo].[DimDate] ([DateKey])

ALTER TABLE [dbo].[FactFinance] CHECK CONSTRAINT [FK_FactFinance_DimDate]

ALTER TABLE [dbo].[FactInternetSales]  WITH CHECK ADD  CONSTRAINT [FK_FactInternetSales_DimDate] FOREIGN KEY([OrderDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])

ALTER TABLE [dbo].[FactInternetSales] CHECK CONSTRAINT [FK_FactInternetSales_DimDate]

ALTER TABLE [dbo].[FactInternetSales]  WITH CHECK ADD  CONSTRAINT [FK_FactInternetSales_DimDate1] FOREIGN KEY([DueDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])

ALTER TABLE [dbo].[FactInternetSales] CHECK CONSTRAINT [FK_FactInternetSales_DimDate1]

ALTER TABLE [dbo].[FactInternetSales]  WITH CHECK ADD  CONSTRAINT [FK_FactInternetSales_DimDate2] FOREIGN KEY([ShipDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])

ALTER TABLE [dbo].[FactInternetSales] CHECK CONSTRAINT [FK_FactInternetSales_DimDate2]

ALTER TABLE [dbo].[FactProductInventory]  WITH CHECK ADD  CONSTRAINT [FK_FactProductInventory_DimDate] FOREIGN KEY([DateKey])
REFERENCES [dbo].[DimDate] ([DateKey])

ALTER TABLE [dbo].[FactProductInventory] CHECK CONSTRAINT [FK_FactProductInventory_DimDate]

ALTER TABLE [dbo].[FactResellerSales]  WITH CHECK ADD  CONSTRAINT [FK_FactResellerSales_DimDate] FOREIGN KEY([OrderDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])

ALTER TABLE [dbo].[FactResellerSales] CHECK CONSTRAINT [FK_FactResellerSales_DimDate]

ALTER TABLE [dbo].[FactSurveyResponse]  WITH CHECK ADD  CONSTRAINT [FK_FactSurveyResponse_DateKey] FOREIGN KEY([DateKey])
REFERENCES [dbo].[DimDate] ([DateKey])

ALTER TABLE [dbo].[FactSurveyResponse] CHECK CONSTRAINT [FK_FactSurveyResponse_DateKey]

end 
