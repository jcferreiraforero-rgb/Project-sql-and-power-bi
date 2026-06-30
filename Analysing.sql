## visualizing 

SELECT
`Transaction Date`,
MONTH(`Transaction Date`) AS MONTH,
DAYNAME(`Transaction Date`) AS DAY,
YEAR(`Transaction Date`) AS YEAR
FROM project_retail.dirty_cafe_sales;

## analyzing per season

SELECT
 CASE 
	WHEN MONTH (`Transaction Date`) IN (3,4,5) THEN	'Spring'
    WHEN MONTH (`Transaction Date`) IN (6,7,8) THEN 'Summer'
    WHEN MONTH (`Transaction Date`) IN (9,10,11) THEN 'Fall'
    WHEN MONTH (`Transaction Date`) IN (12,1,2) THEN 'Winter'
END AS Season,
COUNT(*) AS Total_transactions,
SUM(`Total Spent`) AS Revenue,
AVG(`Total Spent`) AS Avg_transaction
FROM project_retail.dirty_cafe_sales
GROUP BY Season
ORDER BY Revenue DESC;


## Does the item depend on the season?


SELECT
 CASE 
	WHEN MONTH (`Transaction Date`) IN (3,4,5) THEN	'Spring'
    WHEN MONTH (`Transaction Date`) IN (6,7,8) THEN 'Summer'
    WHEN MONTH (`Transaction Date`) IN (9,10,11) THEN 'Fall'
    WHEN MONTH (`Transaction Date`) IN (12,1,2) THEN 'Winter'
END AS Season,
Item,
COUNT(*) AS Times_sold
FROM project_retail.dirty_cafe_sales
GROUP BY Season,Item
ORDER BY Season,Times_sold DESC;

## Create Season column and filling values

ALTER TABLE project_retail.dirty_cafe_sales
ADD COLUMN Season VARCHAR(10);

UPDATE project_retail.dirty_cafe_sales
SET Season = CASE
	WHEN MONTH (`Transaction Date`) IN (3,4,5) THEN	'Spring'
    WHEN MONTH (`Transaction Date`) IN (6,7,8) THEN 'Summer'
    WHEN MONTH (`Transaction Date`) IN (9,10,11) THEN 'Fall'
    WHEN MONTH (`Transaction Date`) IN (12,1,2) THEN 'Winter'
END;

## Analyzing distribution per day

SELECT 
DAYNAME(`Transaction Date`) AS Day,
COUNT(*) AS Total_transactions,
Sum(`Total Spent`) AS Revenue,
AVG(`Total Spent`) AS Avg_transaction
FROM project_retail.dirty_cafe_sales
group by Day
ORDER BY Revenue DESC;


##Analyzing quantity vs revenue

SELECT
Item,
`Price per unit`,
COUNT(*) AS Times_sold,
SUM(`Total Spent`) AS Revenue,
AVG(`Total Spent`) As Avg_transaction,
SUM(Quantity) As Total_units_sold
FROM project_retail.dirty_cafe_sales
GROUP BY Item, `Price per unit`
ORDER BY Revenue DESC;

##Best Location

SELECT
Location,
COUNT(*),
SUM(`Total Spent`) AS Revenue,
AVG(`Total Spent`) AS Avg_transaction,
SUM(Quantity) AS Total_units_sold
FROM project_retail.dirty_cafe_sales
WHERE Location != "UNKNOWN"
GROUP BY Location
ORDER BY Revenue;

## Best selling per location

SELECT
Location,
Item,
COUNT(*),
SUM(`Total Spent`) AS Revenue,
AVG(`Total Spent`) AS Avg_transaction,
SUM(Quantity) AS Total_units_sold
FROM project_retail.dirty_cafe_sales
WHERE Location != "UNKNOWN"
AND Item NOT IN ("Cake/Juice", "Sandwich/Smoothie")
GROUP BY Location, Item
ORDER BY Location, Revenue DESC;

##Payment method
SELECT
 Location,
`Payment Method`,
COUNT(*) AS Total
FROM project_retail.dirty_cafe_sales
WHERE Location != "UNKNOWN"
AND `Payment Method` != "UNKNOWN"
GROUP BY Location, `Payment Method`
ORDER BY Location, Total DESC;








