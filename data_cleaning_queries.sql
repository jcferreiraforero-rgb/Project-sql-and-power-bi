

-- Disable Safe Update Mode 
SET SQL_SAFE_UPDATES = 0;

-- Create initial backup before any changes
CREATE TABLE project_retail.dirty_cafe_sales_backup AS
SELECT * FROM project_retail.dirty_cafe_sales;

-- Refresh backup after cleaning is done
DROP TABLE project_retail.dirty_cafe_sales_backup;
CREATE TABLE project_retail.dirty_cafe_sales_backup AS
SELECT * FROM project_retail.dirty_cafe_sales;


## Diagnostics

# Count total rows
SELECT COUNT(*) FROM project_retail.dirty_cafe_sales;

# Check data types of each column
DESCRIBE project_retail.dirty_cafe_sales;

# Check for duplicates by Transaction ID
SELECT `Transaction ID`, COUNT(*)
FROM project_retail.dirty_cafe_sales
GROUP BY `Transaction ID`
HAVING COUNT(*) > 1;

# Check distinct values per column 
SELECT DISTINCT Item FROM project_retail.dirty_cafe_sales ORDER BY Item;
SELECT DISTINCT `Price Per Unit` FROM project_retail.dirty_cafe_sales ORDER BY `Price Per Unit`;
SELECT DISTINCT `Payment Method` FROM project_retail.dirty_cafe_sales;
SELECT DISTINCT Location FROM project_retail.dirty_cafe_sales;
SELECT DISTINCT `Transaction Date` FROM project_retail.dirty_cafe_sales;

# Count nulls/errors per column
SELECT COUNT(*) AS nulls
FROM project_retail.dirty_cafe_sales
WHERE Item IS NULL OR Item IN ('ERROR', 'UNKNOWN', '');

SELECT COUNT(*) AS nulls
FROM project_retail.dirty_cafe_sales
WHERE `Price Per Unit` IS NULL OR `Price Per Unit` IN ('ERROR', 'UNKNOWN', '');

SELECT COUNT(*) AS nulls
FROM project_retail.dirty_cafe_sales
WHERE `Total Spent` IS NULL OR `Total Spent` IN ('ERROR', 'UNKNOWN', '');

SELECT COUNT(*) AS nulls
FROM project_retail.dirty_cafe_sales
WHERE `Payment Method` IS NULL OR `Payment Method` IN ('ERROR', 'UNKNOWN', '');

SELECT COUNT(*) AS nulls
FROM project_retail.dirty_cafe_sales
WHERE Location IS NULL OR Location IN ('ERROR', 'UNKNOWN', '');

SELECT COUNT(*) AS sin_fecha
FROM project_retail.dirty_cafe_sales
WHERE `Transaction Date` IS NULL
   OR `Transaction Date` = ''
   OR `Transaction Date` IN ('ERROR', 'UNKNOWN');



## TOTAL SPENT — Recalculate from Quantity * Price Per Unit

-- Preview rows with bad Total Spent values
SELECT
    Quantity,
    `Total Spent`,
    `Price Per Unit`,
    Quantity * `Price Per Unit` AS calculated_total
FROM project_retail.dirty_cafe_sales
WHERE `Total Spent` = 'UNKNOWN'
   OR `Total Spent` = 'ERROR'
   OR `Total Spent` IS NULL
   OR `Total Spent` = '';

# Update Total Spent using Quantity * Price Per Unit
UPDATE project_retail.dirty_cafe_sales
SET `Total Spent` = Quantity * `Price Per Unit`
WHERE `Total Spent` = 'UNKNOWN'
   OR `Total Spent` = 'ERROR'
   OR `Total Spent` IS NULL
   OR `Total Spent` = '';

# Verify 
SELECT COUNT(*) AS still_null
FROM project_retail.dirty_cafe_sales
WHERE `Total Spent` IS NULL;



##  ITEM — Fill in based on Price Per Unit

# Price per item

SELECT DISTINCT Item, `Price Per Unit`
FROM project_retail.dirty_cafe_sales
WHERE Item IS NOT NULL AND Item NOT IN ('ERROR', 'UNKNOWN', '')
ORDER BY `Price Per Unit`;

# Count distinct items
SELECT COUNT(DISTINCT Item) AS distinct_items
FROM project_retail.dirty_cafe_sales
WHERE Item IS NOT NULL AND Item NOT IN ('ERROR', 'UNKNOWN', '');

# Preview what the update would look like
SELECT
    Item AS original_item,
    `Price Per Unit`,
    CASE
        WHEN `Price Per Unit` = 1   THEN 'Cookie'
        WHEN `Price Per Unit` = 1.5 THEN 'Tea'
        WHEN `Price Per Unit` = 2   THEN 'Coffee'
        WHEN `Price Per Unit` = 3   THEN 'Cake/Juice'
        WHEN `Price Per Unit` = 4   THEN 'Sandwich/Smoothie'
        WHEN `Price Per Unit` = 5   THEN 'Salad'
        ELSE Item
    END AS new_item
FROM project_retail.dirty_cafe_sales
WHERE Item IS NULL OR Item IN ('ERROR', 'UNKNOWN', '');

# Count rows affected per case before updating
SELECT
    CASE
        WHEN `Price Per Unit` = 1   THEN 'Cookie'
        WHEN `Price Per Unit` = 1.5 THEN 'Tea'
        WHEN `Price Per Unit` = 2   THEN 'Coffee'
        WHEN `Price Per Unit` = 3   THEN 'Cake/Juice'
        WHEN `Price Per Unit` = 4   THEN 'Sandwich/Smoothie'
        WHEN `Price Per Unit` = 5   THEN 'Salad'
        ELSE Item
    END AS new_item,
    COUNT(*) AS rows_affected
FROM project_retail.dirty_cafe_sales
WHERE Item IS NULL OR Item IN ('ERROR', 'UNKNOWN', '')
GROUP BY new_item;

# Apply the update
UPDATE project_retail.dirty_cafe_sales
SET Item = CASE
    WHEN `Price Per Unit` = 1   THEN 'Cookie'
    WHEN `Price Per Unit` = 1.5 THEN 'Tea'
    WHEN `Price Per Unit` = 2   THEN 'Coffee'
    WHEN `Price Per Unit` = 3   THEN 'Cake/Juice'
    WHEN `Price Per Unit` = 4   THEN 'Sandwich/Smoothie'
    WHEN `Price Per Unit` = 5   THEN 'Salad'
    ELSE Item
END
WHERE Item IS NULL OR Item IN ('ERROR', 'UNKNOWN', '');



## PAYMENT METHOD — Standardize invalid values to 'UNKNOWN'


# Check for whitespace issues
SELECT `Payment Method`, LENGTH(`Payment Method`) AS largo, LENGTH(TRIM(`Payment Method`)) AS largo_sin_espacios
FROM project_retail.dirty_cafe_sales
WHERE LENGTH(`Payment Method`) <> LENGTH(TRIM(`Payment Method`));


# Preview bad rows
SELECT `Payment Method`, COUNT(*) AS cantidad
FROM project_retail.dirty_cafe_sales
WHERE `Payment Method` IS NULL
   OR `Payment Method` = ''
   OR `Payment Method` = 'ERROR'
GROUP BY `Payment Method`;

# Update invalid values to 'UNKNOWN'
UPDATE project_retail.dirty_cafe_sales
SET `Payment Method` = 'UNKNOWN'
WHERE `Payment Method` IS NULL
   OR `Payment Method` = ''
   OR `Payment Method` = 'ERROR';

# Verify
SELECT DISTINCT `Payment Method` FROM project_retail.dirty_cafe_sales;



## LOCATION — Standardize invalid values to 'UNKNOWN'

# Preview distinct values
SELECT DISTINCT Location FROM project_retail.dirty_cafe_sales;

-- Count bad rows
SELECT Location, COUNT(*) AS cantidad
FROM project_retail.dirty_cafe_sales
WHERE Location IS NULL
   OR Location = ''
   OR Location IN ('ERROR', 'UNKNOWN')
GROUP BY Location;

# Update invalid values to 'UNKNOWN'
UPDATE project_retail.dirty_cafe_sales
SET Location = 'UNKNOWN'
WHERE Location IS NULL
   OR Location = ''
   OR Location = 'ERROR';

# Verify
SELECT DISTINCT Location FROM project_retail.dirty_cafe_sales;


## TRANSACTION DATE — Delete rows with invalid dates


# Find all non-standard date values
SELECT DISTINCT `Transaction Date`
FROM project_retail.dirty_cafe_sales
WHERE `Transaction Date` IS NULL
   OR `Transaction Date` = ''
   OR `Transaction Date` NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

# Count how many rows would be deleted
SELECT COUNT(*) AS rows_to_delete
FROM project_retail.dirty_cafe_sales
WHERE `Transaction Date` IS NULL
   OR `Transaction Date` = ''
   OR `Transaction Date` NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

# Preview rows before deleting
SELECT *
FROM project_retail.dirty_cafe_sales
WHERE `Transaction Date` IS NULL
   OR `Transaction Date` = ''
   OR `Transaction Date` NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

# Delete rows with invalid dates
DELETE FROM project_retail.dirty_cafe_sales
WHERE `Transaction Date` IS NULL
   OR `Transaction Date` = ''
   OR `Transaction Date` NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';



