		-- Create The Database --
-- Create Database 'DataWarehouse'

USE master;

CREATE DATABASE DataWarehouse;

USE DataWarehouse;
GO
CREATE SCHEMA bronze;
GO	-- separate batches when working with multiple SQL statements
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
------------------------------------------------------------
------------------------------------------------------------
		-- Bronze Layer | DDL Create Tables --
IF OBJECT_ID ('bronze.crm_cust_info' , 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
);

IF OBJECT_ID ('bronze.crm_prd_info' , 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
    prd_id          INT,
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATETIME,
    prd_end_dt      DATETIME,
);

IF OBJECT_ID ('bronze.crm_sales_details' , 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    INT,
    sls_ship_dt     INT,
    sls_due_dt      INT,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
);

IF OBJECT_ID ('bronze.erp_cust_az12' , 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
    cid     NVARCHAR(50),
    bdate   DATE,
    gen     NVARCHAR(50)
);

IF OBJECT_ID ('bronze.erp_loc_a101' , 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
    cid     NVARCHAR(50),
    cntry   NVARCHAR(50)
);

IF OBJECT_ID ('bronze.erp_px_cat_g1v2' , 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(50),
    cat         NVARCHAR(50),
    subcat      NVARCHAR(50),
    maintenance NVARCHAR(50)
);

------------------------------------------------------------
------------------------------------------------------------
        -- Bronze Layer | Load Scripts --
TRUNCATE TABLE bronze.crm_cust_info;    -- Needed to avoid uploading the data more than once
BULK INSERT bronze.crm_cust_info
FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
-- Testing the table
SELECT * FROM bronze.crm_cust_info;
SELECT COUNT(*) FROM bronze.crm_cust_info;  -- The result has to be the same as the number of rows in the .csv file minus one that would be the header

TRUNCATE TABLE bronze.crm_prd_info;
BULK INSERT bronze.crm_prd_info
FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

TRUNCATE TABLE bronze.crm_sales_details;   
BULK INSERT bronze.crm_sales_details
FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

TRUNCATE TABLE bronze.erp_cust_az12;  
BULK INSERT bronze.erp_cust_az12
FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

TRUNCATE TABLE bronze.erp_loc_a101;  
BULK INSERT bronze.erp_loc_a101
FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

TRUNCATE TABLE bronze.erp_px_cat_g1v2;   
BULK INSERT bronze.erp_px_cat_g1v2
FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
------------------------------------------------------------
------------------------------------------------------------
        -- Bronze Layer | Build Stored Procedure -- 
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;    
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '=====================';
        PRINT 'Loading Bronze Layer';
        PRINT '=====================';

        PRINT '-------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;    
        PRINT '>> Inserting Data Into: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';
    
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;
        PRINT '>> Inserting Data Into: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';
    
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;
        PRINT '>> Inserting Data Into: bronze.crm_sales_details' ;  
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';

        PRINT '-------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-------------------';
        
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;  
        PRINT '>> Inserting Data Into: bronze.erp_cust_az12' ;
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';
    
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;  
        PRINT '>> Inserting Data Into: bronze.erp_loc_a101' ;
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';
    
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;   
        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\FabiPC\Downloads\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT '===================================================='
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '>>   - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '===================================================='
    END TRY
    BEGIN CATCH
        PRINT '===================================================='
        PRINT 'ERROR OCURRED DURING LOADING BRONZE LAYER'
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '===================================================='
    END CATCH
END;

-- Test Stored Procedure
EXEC bronze.load_bronze;

------------------------------------------------------------
------------------------------------------------------------
        -- Silver Layer | Exploring Data -- 
SELECT TOP 1000 * FROM bronze.crm_cust_info;
SELECT TOP 1000 * FROM bronze.crm_prd_info;
SELECT TOP 1000 * FROM bronze.crm_sales_details;
SELECT TOP 1000 * FROM bronze.erp_cust_az12;
SELECT TOP 1000 * FROM bronze.erp_loc_a101;
SELECT TOP 1000 * FROM bronze.erp_px_cat_g1v2;

------------------------------------------------------------
------------------------------------------------------------
        -- Silver Layer | DDL Create Tables -- 
IF OBJECT_ID ('silver.crm_cust_info' , 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID ('silver.crm_prd_info' , 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
    prd_id              INT,
    prd_key             NVARCHAR(50),
    prd_nm              NVARCHAR(50),
    prd_cost            INT,
    prd_line            NVARCHAR(50),
    prd_start_dt        DATETIME,
    prd_end_dt          DATETIME,
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID ('silver.crm_sales_details' , 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID ('silver.erp_cust_az12' , 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
    cid              NVARCHAR(50),
    bdate            DATE,
    gen              NVARCHAR(50),
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID ('silver.erp_loc_a101' , 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
    cid                 NVARCHAR(50),
    cntry               NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID ('silver.erp_px_cat_g1v2' , 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 (
    id                  NVARCHAR(50),
    cat                 NVARCHAR(50),
    subcat              NVARCHAR(50),
    maintenance         NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);

------------------------------------------------------------
------------------------------------------------------------
        -- Silver Layer | Load Script 1 --
    -- Check For Nulls or Duplicates in Primary Key
    -- Expectation: No Result
SELECT
    cst_id,
    COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;
-- Check one of the NULL values 
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last	-- The idea is to check for the newest record
FROM bronze.crm_cust_info
WHERE cst_id = 29466;
--
SELECT *
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
	FROM bronze.crm_cust_info
)t WHERE flag_last = 1;	-- This will result in all unique values and most recent ones in duplicates.

    -- Check for unwanted spaces
    -- Expectation: No results
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);   -- It doesn't give results

    -- Data Standardization & Consistency -- In our data warehouse, we aim to store clear and meaningful values rather than using abbreviated terms
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

    -- To test, change all bronze queries to silver
-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

SELECT * FROM silver.crm_cust_info;

    -- Cleaned script
PRINT '>> Truncating Table: silver.crm_cust_info';
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.crm_cust_info';
INSERT INTO silver.crm_cust_info (	-- This is after all the corrections
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)
SELECT	-- First it is recommended to list all columns from the table and then start modifying when needed
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			ELSE 'n/a'
	END cst_marital_status,	-- Normalize marital statues values to readable format
	CASE	WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			ELSE 'n/a'
	END cst_gndr,	-- Normalize gender values to readable format
	cst_create_date
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t WHERE flag_last = 1; -- Select the most recent record per customer
------

------------------------------------------------------------
------------------------------------------------------------
        -- Silver Layer | Load Script 2 --
-- Clean query to start working on
SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info;

-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No result
SELECT
    prd_id,
    COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No results
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;   -- Possible values: NULL, M, R, S, T. Usually you should check the real values for these abbreviatons in the documentation or the people in charge of the DB.

-- Check for Invalid Date Orders
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt; -- Rest of explanation in Google Docs file.

SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')

-- Final query
SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,  -- Takes the first strings and replace the '-' character to find a match with ERP table later
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,         -- Does the same as the previous, but with the 2nd part of the prd_key strings
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,
    CASE    UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info;

-- DDL
IF OBJECT_ID ('silver.crm_prd_info' , 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          NVARCHAR(50),
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATE,
    prd_end_dt      DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

    -- Clean query
PRINT '>> Truncating Table: silver.crm_prd_info';
TRUNCATE TABLE silver.crm_prd_info;
PRINT '>> Inserting Data Into: silver.crm_prd_info';
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,  -- Extract category ID (plus change separators)
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,         -- Extract product key
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,
    CASE    UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
    END AS prd_line,    -- Map product line codes to descriptive values
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(
        LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
        AS DATE
    ) AS prd_end_dt -- Calculate end date as one day before the next start date
FROM bronze.crm_prd_info;

    -- Check quality of silver table
-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No result
SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

SELECT *
FROM silver.crm_prd_info;

------------------------------------------------------------
------------------------------------------------------------
        -- Silver Layer | Load Script 3 --
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE    WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL   -- Based on the cleanup results, there were some values that had less than 8 characters.
            ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)            -- In SQL, double cast is needed to pass from INT to DATE.
    END AS sls_order_dt,
    CASE    WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL   -- Just in case there are issues like with sls_order_dt, better to apply same fixes.
            ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)           
    END AS sls_ship_dt,
    CASE    WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL   -- Just in case there are issues like with sls_order_dt, better to apply same fixes.
            ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)           
    END AS sls_due_dt,
    CASE    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) -- Use ABS to make values always positive
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE    WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
    END sls_price
FROM bronze.crm_sales_details
-- WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_prd_info)   -- It confirms that the cust_id from both tables can be used
-- WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)  -- It confirms that the prd_key from both tables can be used
-- WHERE sls_ord_num != TRIM(sls_ord_num); -- If all strings are okay, it should get an empty result.

    -- Check for Invalid Dates
SELECT
    NULLIF(sls_order_dt, 0) sls_order_dt    -- There are NULL values so it needed to be handled
FROM bronze.crm_sales_details
WHERE   sls_order_dt <= 0           -- Checks there are no negative values since those can't be CAST to a DATE.
OR      LEN(sls_order_dt) != 8      -- Checks if there are values with different amount of characters
OR      sls_order_dt > 20500101     -- Checks if there are dates later than the one give by the business.
OR      sls_order_dt < 19000101     -- Checks if there are dates before than the one give by the business.
-- Full cleanup made in main query

SELECT
    NULLIF(sls_ship_dt, 0) sls_ship_dt    
FROM bronze.crm_sales_details
WHERE   sls_ship_dt <= 0           
OR      LEN(sls_ship_dt) != 8      
OR      sls_ship_dt > 20500101    
OR      sls_ship_dt < 19000101   
-- Final result of query is perfect, so no need of cleanup

SELECT
    NULLIF(sls_due_dt, 0) sls_due_dt    
FROM bronze.crm_sales_details
WHERE   sls_due_dt <= 0           
OR      LEN(sls_due_dt) != 8      
OR      sls_due_dt > 20500101    
OR      sls_due_dt < 19000101   
-- Final result of query is perfect, so no need of cleanup

-- Order Date must always be earlier than the Shipping Date or Due date
SELECT
    *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt
-- Final result of query is perfect, so no need of transformations

/* Business Rules:
    Sales = Quantity * Price
    Negative, Zeros, Nulls are not allows!! */
SELECT DISTINCT
    sls_sales AS old_sls_sales,
    sls_quantity,
    sls_price AS old_sls_price,
    CASE    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) -- Use ABS to make values always positive
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
    END AS sls_sales,
    CASE    WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
    END sls_price
FROM bronze.crm_sales_details
WHERE   sls_sales != sls_quantity * sls_price
OR      sls_sales IS NULL
OR      sls_quantity IS NULL
OR      sls_price IS NULL
OR      sls_sales <= 0
OR      sls_quantity <= 0
OR      sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price
-- There is a lot of issues. There is a need to talk with the Data Experts:
    -- Solution #1: Data Issues will be fixed direct in source system
    -- Solution #2: Data Issues has to be fixed in data warehouse.
-- Rules (applied in main query):
    -- If Sales is negative, zero, or null, derive it using Quantity and Price.
    -- If Price is zero or null, calculate it using Sales and Quantity.
    -- If Price is negative, convert it to a positive value.
        
     -- Clean query
PRINT '>> Truncating Table: silver.crm_sales_details';
TRUNCATE TABLE silver.crm_sales_details;
PRINT '>> Inserting Data Into: silver.crm_sales_details';
INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE    WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL   -- Based on the cleanup results, there were some values that had less than 8 characters.
            ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)            -- In SQL, double cast is needed to pass from INT to DATE.
    END AS sls_order_dt,
    CASE    WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL   -- Just in case there are issues like with sls_order_dt, better to apply same fixes.
            ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)           
    END AS sls_ship_dt,
    CASE    WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL   -- Just in case there are issues like with sls_order_dt, better to apply same fixes.
            ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)           
    END AS sls_due_dt,
    CASE    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) -- Use ABS to make values always positive
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE    WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
    END sls_price
FROM bronze.crm_sales_details;

    -- Check health of silver table
-- Check for Invalid Dates
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE   sls_sales != sls_quantity * sls_price
OR      sls_sales IS NULL
OR      sls_quantity IS NULL
OR      sls_price IS NULL
OR      sls_sales <= 0
OR      sls_quantity <= 0
OR      sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

SELECT * FROM silver.crm_sales_details;

------------------------------------------------------------
------------------------------------------------------------
        -- Silver Layer | Load Script 4 --
    -- 1st table
SELECT
    cid,
    bdate,
    gen
FROM bronze.erp_cust_az12;   -- Based on drawio schema, it is possible to connect 'cid' with 'cst_key' in crm_cust_info table
  
SELECT * FROM [silver].[crm_cust_info];

-- Fixed query
SELECT
    CASE    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))   -- Remove 'NAS' prefix if present
            ELSE cid
    END cid,
    CASE    WHEN bdate > GETDATE() THEN NULL
            ELSE bdate
    END AS bdate,   -- Set future birthdates to NULL
    CASE    WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'n/a'
    END AS gen      -- Normalize gender values and handle unknown cases
FROM bronze.erp_cust_az12
/* WHERE     CASE    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))   
                  ELSE cid
          END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);
This WHERE clause is used to check there are no values outside the fix */

    -- Identify Ouf-of-Range Dates
SELECT DISTINCT
    bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()
-- There are dates outside the boundary. Should check with data expert to see how to handle those, but for this case we are gonna handle the most absurd ones (dates > today)

    -- Data Standardization & Consistency
SELECT DISTINCT 
    gen
FROM bronze.erp_cust_az12;
-- There are several values (NULL, F, '', Male, Female and M), which is wrong.

    -- Time to insert it into the silver layer after checking there were no data type modifications.
PRINT '>> Truncating Table: silver.erp_cust_az12';
TRUNCATE TABLE silver.erp_cust_az12;
PRINT '>> Inserting Data Into: silver.erp_cust_az12';
INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
SELECT
    CASE    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))   -- Some values have 'NAS' before the valid value and some don't, hence the extraction with SUBSTRING()
            ELSE cid
    END cid,
    CASE    WHEN bdate > GETDATE() THEN NULL
            ELSE bdate
    END AS bdate,
    CASE    WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12;

    -- Data quality check
-- Identify Ouf-of-Range Dates
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT 
    gen
FROM silver.erp_cust_az12;

SELECT * FROM silver.erp_cust_az12;

    -- 2nd table
SELECT
    cid,
    cntry
FROM bronze.erp_loc_a101;   -- Based on drawio schema, it is possible to connect 'cid' with 'cst_key' in crm_cust_info table
 
SELECT cst_key FROM silver.crm_cust_info;   -- There is a '-' between 'AW' and the numbers, so it needs to be fixed.

    -- Final query
SELECT
    REPLACE(cid, '-', '') cid,
    CASE    WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
    END cntry
FROM bronze.erp_loc_a101
-- WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info) -- To double check there are no other possible issues

    -- Data Standardization & Consistency
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;
-- There are several invalid values (countries written in both long and short form, NULLs, empty strings)
-- Check fix
SELECT DISTINCT
    cntry AS old_cntry,
    CASE    WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
    END cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;
-- It looks correct

    -- Time to insert it into the silver layer after checking there were no data type modifications.
PRINT '>> Truncating Table: silver.erp_loc_a101';
TRUNCATE TABLE silver.erp_loc_a101;
PRINT '>> Inserting Data Into: silver.erp_loc_a101';
INSERT INTO silver.erp_loc_a101(cid, cntry)
SELECT
    REPLACE(cid, '-', '') cid,
    CASE    WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
    END cntry   -- Normalize and Handle missing or blank country codes
FROM bronze.erp_loc_a101

    -- Data quality check
-- Data Standardization & Consistency
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

SELECT * FROM silver.erp_loc_a101;

     -- 3rd table
SELECT
    id,             -- The table 'crm_prd_info' has the column 'cat_id' prepared by us for this column, so no action is needed.
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;    -- It is possible to connect this table with 'id' to the 'prd_key' in the 'crm_prd_info'.

    -- Check for unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)
-- No empty spaces, so it is all good.

    -- Data Standardization & Consistency
SELECT DISTINCT
    cat
FROM bronze.erp_px_cat_g1v2;
-- All values look good

SELECT DISTINCT
    subcat
FROM bronze.erp_px_cat_g1v2;
-- All values look good

SELECT DISTINCT
    maintenance
FROM bronze.erp_px_cat_g1v2;
-- All values look good

    -- Time to insert it into the silver layer after checking there were no data type modifications. (No cleanups were needed)
PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
TRUNCATE TABLE silver.erp_px_cat_g1v2;
PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
SELECT
    id,            
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;

    -- Data quality check
SELECT * FROM silver.erp_px_cat_g1v2;

--=== ADDED TRUNCATE AND A PRINT MESSAGE TO ALL TABLES ===--
PRINT '>> Truncating Table: silver.';
TRUNCATE TABLE silver.
PRINT '>> Inserting Data Into: silver.';

------------------------------------------------------------
------------------------------------------------------------
        -- Silver Layer | Build Stored Procedure --
    -- Full code
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;    
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '=====================';
        PRINT 'Loading Silver Layer';
        PRINT '=====================';

        PRINT '---------------------';
        PRINT 'Loading CRM Tables';
        PRINT '---------------------';

        -- Loading silver.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Inserting Data Into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (	
	        cst_id,
	        cst_key,
	        cst_firstname,
	        cst_lastname,
	        cst_marital_status,
	        cst_gndr,
	        cst_create_date)
        SELECT	
	        cst_id,
	        cst_key,
	        TRIM(cst_firstname) AS cst_firstname,
	        TRIM(cst_lastname) AS cst_lastname,
	        CASE	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			        ELSE 'n/a'
	        END cst_marital_status,	
	        CASE	WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			        ELSE 'n/a'
	        END cst_gndr,
	        cst_create_date
        FROM (
	        SELECT
		        *,
		        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
	        FROM bronze.crm_cust_info
	        WHERE cst_id IS NOT NULL
        )t WHERE flag_last = 1;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';

        -- Loading silver.crm_prd_info
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Inserting Data Into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,  
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,         
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE    UPPER(TRIM(prd_line))
                    WHEN 'M' THEN 'Mountain'
                    WHEN 'R' THEN 'Road'
                    WHEN 'S' THEN 'other Sales'
                    WHEN 'T' THEN 'Touring'
                    ELSE 'n/a'
            END AS prd_line,    
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
                AS DATE
            ) AS prd_end_dt 
        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';
        
        -- Loading silver.crm_sales_details
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Inserting Data Into: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE    WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL   
                    ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE    WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL   
                    ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)           
            END AS sls_ship_dt,
            CASE    WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL   
                    ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)           
            END AS sls_due_dt,
            CASE    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
                        THEN sls_quantity * ABS(sls_price)
                    ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE    WHEN sls_price IS NULL OR sls_price <= 0
                        THEN sls_sales / NULLIF(sls_quantity, 0)
                    ELSE sls_price
            END sls_price
        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';

        -- Loading silver.erp_cust_az12
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Inserting Data Into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))   
                    ELSE cid
            END cid,
            CASE    WHEN bdate > GETDATE() THEN NULL
                    ELSE bdate
            END AS bdate,
            CASE    WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                    WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                    ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';

        -- Loading silver.erp_loc_a101
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Inserting Data Into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101(cid, cntry)
        SELECT
            REPLACE(cid, '-', '') cid,
            CASE    WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                    WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                    WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                    ELSE TRIM(cntry)
            END cntry
        FROM bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';

        -- Loading silver.erp_px_cat_g1v2
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
        SELECT
            id,            
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------';
            SET @batch_end_time = GETDATE();
        PRINT '===================================================='
        PRINT 'Loading Silver Layer is Completed';
        PRINT '>>   - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '===================================================='
    END TRY
    BEGIN CATCH
        PRINT '===================================================='
        PRINT 'ERROR OCURRED DURING LOADING SILVER LAYER'
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '===================================================='
    END CATCH
END;

    -- Test result
EXEC silver.load_silver;

