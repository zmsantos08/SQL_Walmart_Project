-- 1. Project Overview
-- 2. Data Collection
-- 3. Data Cleaning and Validation

-- Changing the Table name
ALTER TABLE walmart.walmart_sales_XPTO
RENAME TO  walmart.walmart_sales_backup;

-- Creating a duplicate table
CREATE TABLE walmart_sales AS
SELECT * FROM walmart_sales_backup;

SELECT * -- GENERAL SELECT STATEMENT
FROM walmart_sales;

-- Finding duplicates

SELECT *
FROM (
SELECT*,
	ROW_NUMBER() OVER(
		PARTITION BY Store, Date, Weekly_Sales, Holiday_Flag, Temperature, Fuel_Price, CPI, Unemployment
	) AS row_num 
	FROM walmart_sales) 
    as ranked
WHERE row_num > 1;

-- Convert date from STR to Date

ALTER TABLE walmart_sales
ADD COLUMN Date_new DATE;

UPDATE walmart_sales
SET Date_new = STR_TO_DATE(Date, '%Y-%m-%d');

ALTER TABLE walmart_sales
DROP COLUMN Date;

ALTER TABLE walmart_sales
CHANGE COLUMN Date_new date DATE;

-- Convert Temperature from Fahrenheit to Celsius

UPDATE walmart_sales
SET Temperature = ((Temperature-32)*(5/9));

-- Inserting Holiday Types
   
ALTER TABLE walmart_sales
ADD COLUMN Day_Type TEXT;

UPDATE walmart_sales
SET Day_Type = 
    CASE
        WHEN Date IN ('2010-02-12', '2011-02-11', '2012-02-10', '2013-02-08') THEN 'Super Bowl'
        WHEN Date IN ('2010-09-10', '2011-09-09', '2012-09-07', '2013-09-06') THEN 'Labour Day'
        WHEN Date IN ('2010-11-26', '2011-11-25', '2012-11-23', '2013-11-29') THEN 'Thanksgiving'
        WHEN Date IN ('2010-12-31', '2011-12-30', '2012-12-28', '2013-12-27') THEN 'Christmas'
        ELSE 'Normal Day'
     END;

-- Validate Data Ranges

SELECT MIN(Store), MAX(Store), COunt(distinct(Store))
FROM walmart_sales;

SELECT MIN(Weekly_sales), MAX(Weekly_sales), COunt(distinct(Weekly_sales))
FROM walmart_sales;

SELECT MIN(Date), MAX(Date), COunt(distinct(Date))
FROM walmart_sales;

SELECT MIN(Holiday_flag), MAX(Holiday_flag), COunt(distinct(Holiday_flag))
FROM walmart_sales;

SELECT MIN(temperature), MAX(temperature), COunt(distinct(temperature))
FROM walmart_sales;

SELECT MIN(fuel_price), MAX(fuel_price), COunt(distinct(fuel_price))
FROM walmart_sales;

SELECT MIN(CPI), MAX(CPI), COunt(distinct(CPI))
FROM walmart_sales;

SELECT MIN(Unemployment), MAX(Unemployment), COunt(distinct(Unemployment))
FROM walmart_sales;

-- 4. Data Analysis

-- Store Performance
-- Yearly Total Sales Trend

SELECT EXTRACT(YEAR FROM Date) AS Sale_Year, ROund(SUM(Weekly_Sales)) AS Total_Yearly_Sales 
FROM Walmart_Sales 
GROUP BY Sale_Year 
ORDER BY Sale_Year;

-- TOP5 Stores by Weekly Sales

SELECT Store, Round(AVG(Weekly_Sales)) AS Average_Sales
FROM Walmart_Sales
GROUP BY Store
ORDER BY Average_Sales DESC
LIMIT 5;

-- Bottom 5 Stores by Weekly Sales

SELECT Store, Round(AVG(Weekly_Sales)) AS Average_Sales
FROM Walmart_Sales
GROUP BY Store
ORDER BY Average_Sales ASC
LIMIT 5;

-- Variance between stores in weekly sales

SELECT Store,
    -- Average Weekly Sales
    CAST(AVG(Weekly_Sales) AS DECIMAL(18, 2)) AS Average_Weekly_Sales,

    -- Standard Deviation of Weekly Sales
    CAST(STDDEV(Weekly_Sales) AS DECIMAL(18, 2)) AS StDev_Weekly_Sales,

    -- Coefficient of Variation (CV)
      CAST(
        (STDDEV(Weekly_Sales) / AVG(Weekly_Sales)) * 100
        AS DECIMAL(18, 2)
    ) AS Coefficient_of_Variation_CV
FROM Walmart_Sales
GROUP BY Store
ORDER BY Coefficient_of_Variation_CV DESC
LIMIT 5;

-- Holiday Impact on Sales
-- AVG Sales on holidays VS not holidays

SELECT holiday_flag, round(avg(weekly_sales)) as avg_weekly_sales
FROM walmart_sales
GROUP BY holiday_flag;

-- AVG Sales with Holiday_Flag = 1
SELECT ROUND(AVG(weekly_sales))
FROM walmart_sales
WHERE holiday_flag = 1;

-- AVG Sales with Holiday_Flag = 0
SELECT ROUND(AVG(weekly_sales))
FROM walmart_sales
WHERE holiday_flag = 0;

-- Percentage difference from weekly sales on holiday weeks vs normal weeks
SELECT (
((SELECT ROUND(AVG(weekly_sales))
FROM walmart_sales
WHERE holiday_flag = 1)
-
(SELECT ROUND(AVG(weekly_sales))
FROM walmart_sales
WHERE holiday_flag = 0))
/
(SELECT ROUND(AVG(weekly_sales))
FROM walmart_sales
WHERE holiday_flag = 0))
*100 as avg_increase_sales_holiday;

-- AVG Sales per Day_Type Holiday

SELECT Day_Type, count(Day_Type)
FROM walmart_sales
GROUP BY Day_Type;

SELECT Day_Type, ROUND(AVG(Weekly_Sales),0) as AVG_Weekly_Sales
FROM walmart_sales
GROUP BY Day_Type
ORDER BY AVG_Weekly_Sales DESC;

SELECT ((1471273-1041256)/1041256)*100 as Percentage_Difference_Thanksgiving;

SELECT ((960833-1041256)/1041256)*100 as Percentage_Difference_Christmas;

-- Fuel Price and CPI Analysis

SELECT MIN(Fuel_price), AVG(Fuel_price), MAX(Fuel_price)
FROM walmart_sales;

SELECT Round(AVG(Weekly_Sales)) as AVG_Weekly_Sales_High_Fuel_Price
FROM walmart_sales
WHERE Fuel_Price >= 
	(
	SELECT AVG(Fuel_Price)
	FROM walmart_sales
	);

SELECT ROund(AVG(Weekly_Sales)) as AVG_Weekly_Sales_Low_Fuel_Price
FROM walmart_sales
WHERE Fuel_Price < 
	(
	SELECT AVG(Fuel_Price)
	FROM walmart_sales
	);

SELECT ((1047613-1046209)/1046209)*100 as Percentage_difference_High_Low_Fuel_Price;

SELECT ROund(AVG(Weekly_Sales)) as AVG_Weekly_Sales_High_Fuel_Price
FROM walmart_sales
WHERE Fuel_Price >= 4 ;

SELECT ROund(AVG(Weekly_Sales)) as AVG_Weekly_Sales_Low_Fuel_Price
FROM walmart_sales
WHERE Fuel_Price < 3 ;

-- Difference between AVG weekly sales with very high fuel prices VS very low fuel prices
SELECT 
( -- AVG Weekly sales with very high fuel price
SELECT Round(AVG(Weekly_Sales)) as AVG_Weekly_Sales_High_Fuel_Price
FROM walmart_sales
WHERE Fuel_Price >= 4
)
- 
( -- AVG Weekly sales with very low fuel price
SELECT Round(AVG(Weekly_Sales)) as AVG_Weekly_Sales_Low_Fuel_Price
FROM walmart_sales
WHERE Fuel_Price < 3
) as Sales_Difference_Fuel_Price_Extremes;

-- Percentage difference between AVG weekly sales with very high fuel prices VS very low fuel prices
SELECT 
(
SELECT 
(
SELECT Round(AVG(Weekly_Sales)) as AVG_Weekly_Sales_High_Fuel_Price
	FROM walmart_sales
	WHERE Fuel_Price >= 4
)
- 
(
SELECT Round(AVG(Weekly_Sales)) as AVG_Weekly_Sales_Low_Fuel_Price
	FROM walmart_sales
	WHERE Fuel_Price < 3
) as Sales_Difference_Fuel_Price_Extremes
) 
/ 
(SELECT Round(AVG(Weekly_Sales)) as AVG_Weekly_Sales_Low_Fuel_Price
FROM walmart_sales
WHERE Fuel_Price < 3)
 * 100 as Percentage_Difference_Fuel_Price_Extremes
;

-- Impact of Unemployment

SELECT ROUND(Unemployment, 0) AS Unemployment_Level, ROUND(AVG(Weekly_Sales)) AS Average_Weekly_Sales 
FROM Walmart_Sales 
GROUP BY Unemployment_Level 
ORDER BY Average_weekly_Sales DESC;

SELECT 
(
	(SELECT round(AVG(Weekly_Sales))
	FROM walmart_sales
	WHERE round(unemployment,0) = 4)
-
	(SELECT round(AVG(Weekly_Sales))
	FROM walmart_sales
	WHERE round(unemployment,0) = 14)
)
/
(SELECT round(AVG(Weekly_Sales))
	FROM walmart_sales
	WHERE round(unemployment,0) = 14)
* 100 as Percentage_Difference_Unemployment_Gap
;

-- Impact of CPI on weekly sales

SELECT ROUND(MIN(CPI)), ROUND(AVG(CPI)), ROUND(MAX(CPI))
FROM walmart_sales;

SELECT
ROUND( 
	(
		(
        SELECT AVG(weekly_sales)
		FROM walmart_sales
		WHERE CPI <= (SELECT AVG(CPI) FROM walmart_sales)
		)
-
		(
		SELECT AVG(weekly_sales)
		FROM walmart_sales
		WHERE CPI > (SELECT AVG(CPI)  FROM walmart_sales)
        )
	)
/
	(
    SELECT AVG(weekly_sales)
	FROM walmart_sales
	WHERE CPI > (SELECT AVG(CPI) FROM walmart_sales)
	)
 * 100, 2) as Percentage_Difference_AVG_WeeklySales_CPI
;

-- Temperature impact on weekly Sales

SELECT MIN(temperature), AVG(Temperature), MAX(Temperature)
FROM walmart_sales;

SELECT
    CASE
        WHEN Temperature <= 0 THEN 'Freezing'
        WHEN Temperature > 0 AND Temperature <= 16 THEN 'Cold'
        WHEN Temperature > 16 AND Temperature <= 30 THEN 'Warm'
        WHEN Temperature > 30 THEN 'Very Hot'
              ELSE 'NULL'
    END AS Temperature_Bin,
    COUNT(Weekly_Sales) AS Num_Records,
    CAST(AVG(Weekly_Sales) AS DECIMAL(18, 2)) AS AVG_Weekly_Sales
FROM
    Walmart_Sales
GROUP BY
    Temperature_Bin
ORDER BY
    AVG_weekly_Sales;
    
SELECT ROUND(AVG(weekly_sales))
FROM walmart_sales;

SELECT ROUND((890221.27-1046965)/1046965*100,2) 
as Percent_Dif_Weekly_Sales_Temp_Very_Hot;

-- Correlations between Weekly Sales and Factors

SELECT
    (
        (AVG(Weekly_Sales * Temperature) - (AVG(Weekly_Sales) * AVG(Temperature)))
        /
        (
            SQRT(AVG(Weekly_Sales * Weekly_Sales) - (AVG(Weekly_Sales) * AVG(Weekly_Sales)))
            *
            SQRT(AVG(Temperature * Temperature) - (AVG(Temperature) * AVG(Temperature)))
        )
    ) AS Corr_Sales_Temperature,
    (    -- 2. Correlation with CPI
        (AVG(Weekly_Sales * CPI) - (AVG(Weekly_Sales) * AVG(CPI)))
        /
        (
            SQRT(AVG(Weekly_Sales * Weekly_Sales) - (AVG(Weekly_Sales) * AVG(Weekly_Sales)))
            *
            SQRT(AVG(CPI * CPI) - (AVG(CPI) * AVG(CPI)))
        )
    ) AS Corr_Sales_CPI,
    (    -- 3. Correlation with Unemployment
        (AVG(Weekly_Sales * Unemployment) - (AVG(Weekly_Sales) * AVG(Unemployment)))
        /
        (
            SQRT(AVG(Weekly_Sales * Weekly_Sales) - (AVG(Weekly_Sales) * AVG(Weekly_Sales)))
            *
            SQRT(AVG(Unemployment * Unemployment) - (AVG(Unemployment) * AVG(Unemployment)))
        )
    ) AS Corr_Sales_Unemployment,
    (    -- 4. Correlation with Fuel_Price (Newly Added)
        (AVG(Weekly_Sales * Fuel_Price) - (AVG(Weekly_Sales) * AVG(Fuel_Price)))
        /
        (
            SQRT(AVG(Weekly_Sales * Weekly_Sales) - (AVG(Weekly_Sales) * AVG(Weekly_Sales)))
            *
            SQRT(AVG(Fuel_Price * Fuel_Price) - (AVG(Fuel_Price) * AVG(Fuel_Price)))
        )
    ) AS Corr_Sales_FuelPrice,
    (     -- 5. Correlation with Holiday_Flag (Newly Added)
        (AVG(Weekly_Sales * Holiday_Flag) - (AVG(Weekly_Sales) * AVG(Holiday_Flag)))
        /
        (
            SQRT(AVG(Weekly_Sales * Weekly_Sales) - (AVG(Weekly_Sales) * AVG(Weekly_Sales)))
            *
            SQRT(AVG(Holiday_Flag * Holiday_Flag) - (AVG(Holiday_Flag) * AVG(Holiday_Flag)))
        )
	) AS Corr_Sales_Holidays
FROM Walmart_Sales;