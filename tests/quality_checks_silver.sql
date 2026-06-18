
/*
================================================================================
Quality Checks
================================================================================
Script Purpose:
    This script performrs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schemas. It includes checks for:
    - Null of duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
================================================================================
*/

-- ================================================================================
-- Checking 'silver.crm_cust_info'
-- ================================================================================
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

-- ================================================================================
-- Checking 'silver.crm_prd_info'
-- ================================================================================
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
WHERE prd_end_dt < prd_start_dt;

SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');

-- ================================================================================
-- Checking 'silver.crm_sales_details'
-- ================================================================================
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

-- ================================================================================
-- Checking 'silver.erp_cust_az12'
-- ================================================================================
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

-- ================================================================================
-- Checking 'silver.erp_loc_a101'
-- ================================================================================
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

-- ================================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ================================================================================
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
