------------------------------------------------------------
------------------------------------------------------------
		-- Gold Layer | Build Dimension Customers --
/* SELECT cst_id, COUNT(*) FROM ( -- After Joining tables, check if any duplicates were introduced by the JOIN logic */
	SELECT			-- Checking integration_model.drawio -> join all CUSTOMER tables
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,	
		CASE	WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr	 -- Original column was 'ci.cst_gndr', fix explanation is below
				ELSE COALESCE(ca.gen, 'n/a')
		END AS new_gen,
		ci.cst_create_date,
		ca.bdate,
		la.cntry
	FROM silver.crm_cust_info ci
	LEFT JOIN	silver.erp_cust_az12 ca
	ON			ci.cst_key = ca.cid
	LEFT JOIN	silver.erp_loc_a101 la
	ON			ci.cst_key = la.cid
/* )t GROUP BY cst_id
HAVING COUNT(*) > 1; (2nd part of checking duplicates query) */

-- There is an integration error where Gender in this case is brought up twice
SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	-- Applying business rule
	CASE	WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr	 -- CRM is the Master for gender Info
			ELSE COALESCE(ca.gen, 'n/a')
	END AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN	silver.erp_cust_az12 ca
ON			ci.cst_key = ca.cid
LEFT JOIN	silver.erp_loc_a101 la
ON			ci.cst_key = la.cid
ORDER BY 1, 2;
-- There are cases of gender mismatch and NULLs. NULLs often come from joined tables and will appear if SQL finds no matches.
-- Things to ask the data expert: Which source is the master for these values? For this exercise let's pretend that it is the data in the CRM.

	-- Cleaned query - Sort the columns into logical groups to improve readability
CREATE VIEW gold.dim_customers AS							-- View creation (Dimension)
SELECT			-- Using 'General Principles' to change column names
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,	-- Creation of Surrogate Key
	ci.cst_id				AS customer_id,
	ci.cst_key				AS customer_number,
	ci.cst_firstname		AS first_name,
	ci.cst_lastname			AS last_name,
	la.cntry				AS country,
	ci.cst_marital_status	AS marital_status,	
	CASE	WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
			ELSE COALESCE(ca.gen, 'n/a')
	END						AS gender,
	ca.bdate				AS birthdate,
	ci.cst_create_date		AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN	silver.erp_cust_az12 ca
ON			ci.cst_key = ca.cid
LEFT JOIN	silver.erp_loc_a101 la
ON			ci.cst_key = la.cid

	-- Quality Check for the Gold Table
SELECT * FROM gold.dim_customers;

SELECT DISTINCT gender FROM gold.dim_customers;

------------------------------------------------------------
------------------------------------------------------------
		-- Gold Layer | Build Dimension Products --
/* SELECT prd_key, COUNT(*) FROM ( -- After Joining tables, check if any duplicates were introduced by the JOIN logic */
	SELECT
		pn.prd_id,
		pn.cat_id,
		pn.prd_key,
		pn.prd_nm,
		pn.prd_cost,
		pn.prd_line,
		pn.prd_start_dt,
		pc.cat,
		pc.subcat,
		pc.maintenance
	FROM silver.crm_prd_info pn
	LEFT JOIN	silver.erp_px_cat_g1v2 pc
	ON			pn.cat_id = pc.id
	WHERE prd_end_dt IS NULL 	-- There is a need to filter out the historical data, and only use the current data
/* )t GROUP BY prd_key
HAVING COUNT(*) > 1  (2nd part of checking duplicates query) */

	-- Cleaned query - Sort the columns into logical groups to improve readability
CREATE VIEW gold.dim_products AS	-- View creation (Dimension)
SELECT
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,	-- Creation of Surrogate Key
	pn.prd_id		AS product_id,
	pn.prd_key		AS product_number,
	pn.prd_nm		AS product_name,
	pn.cat_id		AS category_id,
	pc.cat			AS category,
	pc.subcat		AS subcategory,
	pc.maintenance,
	pn.prd_cost		AS cost,
	pn.prd_line		AS product_line,
	pn.prd_start_dt	AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN	silver.erp_px_cat_g1v2 pc
ON			pn.cat_id = pc.id
WHERE prd_end_dt IS NULL

	-- Quality check of View
SELECT * FROM gold.dim_products;

------------------------------------------------------------
------------------------------------------------------------
		-- Gold Layer | Build Fact Sales --
CREATE VIEW gold.fact_sales AS	-- View creation (Fact)
SELECT
	sd.sls_ord_num		AS order_number,
	pr.product_key,	-- Replaces 'sd.sls_prd_key' with the Surrogate Key from the 'products' dimension
	cu.customer_key,	-- Replaces 'sd.sls_cust_id' with the Surrogate Key from the 'customers' dimension
	sd.sls_order_dt		AS order_date,
	sd.sls_ship_dt		AS shipping_date,
	sd.sls_due_dt		AS due_date,
	sd.sls_sales		AS sales_amount,
	sd.sls_quantity		AS quantity,
	sd.sls_price		AS price
FROM silver.crm_sales_details sd
LEFT JOIN	gold.dim_products pr
ON			sd.sls_prd_key = pr.product_number
LEFT JOIN	gold.dim_customers cu
ON			sd.sls_cust_id = cu.customer_id

	-- Quality check of View
SELECT * FROM gold.fact_sales;

	-- Fact check
-- Foreign Key Integrity (Dimensions)
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE c.customer_key IS NULL;	-- Shouldn't give any results back, which means that everything is matching perfectly
-- WHERE p.product_key IS NULL;	-- Shouldn't give any results back, which means that everything is matching perfectly

------------------------------------------------------------
------------------------------------------------------------
		-- Gold Layer | Build Fact Sales --
