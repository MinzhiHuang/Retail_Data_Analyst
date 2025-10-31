-- ==========================================
-- DATA QUALITY CHECKS - OPTIMIZED VERSION
-- Last Updated: 2025-10-30
-- ==========================================

-- ==========================================
-- 1. DATA CLEANING
-- ==========================================

-- Remove records with data errors
DELETE FROM customer_transactions
WHERE data_errors::text != '[]';

select COUNT(*) from customer_transactions;
-- ==========================================
-- 2. PRIMARY KEY INTEGRITY
-- ==========================================

-- Check for duplicate or null primary keys
SELECT 'customer_demographics PK' AS check_name, customer_id, COUNT(*) AS dup_cnt 
FROM customer_demographics
GROUP BY customer_id
HAVING customer_id IS NULL OR COUNT(*) > 1;

SELECT 'store_info PK' AS check_name, store_id, COUNT(*) AS dup_cnt
FROM store_info
GROUP BY store_id
HAVING store_id IS NULL OR COUNT(*) > 1;

SELECT 'transactions composite key' AS check_name, 
       customer_id, store_id, month, COUNT(*) AS dup_cnt
FROM customer_transactions
GROUP BY customer_id, store_id, month
HAVING COUNT(*) > 1;


-- ==========================================
-- 3. FOREIGN KEY INTEGRITY
-- ==========================================

-- Check for orphaned records
SELECT 'Orphaned customer_id' AS issue, t.customer_id
FROM customer_transactions t
LEFT JOIN customer_demographics d ON d.customer_id = t.customer_id
WHERE d.customer_id IS NULL;

SELECT 'Orphaned store_id' AS issue, t.store_id
FROM customer_transactions t
LEFT JOIN store_info s ON s.store_id = t.store_id
WHERE s.store_id IS NULL;


-- ==========================================
-- 4. NULL VALUE ANALYSIS
-- ==========================================

-- Comprehensive NULL check function
CREATE OR REPLACE FUNCTION check_all_nulls()
RETURNS TABLE (
    table_name TEXT,
    column_name TEXT,
    total_records BIGINT,
    null_count BIGINT,
    null_percentage NUMERIC
) AS $$
DECLARE
    tbl TEXT;
    col TEXT;
    total BIGINT;
    nulls BIGINT;
BEGIN
    FOR tbl IN 
        SELECT t.table_name 
        FROM information_schema.tables t
        WHERE t.table_schema = 'public' 
          AND t.table_name IN ('customer_demographics', 'store_info', 'customer_transactions')
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I', tbl) INTO total;
        
        FOR col IN 
            SELECT c.column_name 
            FROM information_schema.columns c
            WHERE c.table_schema = 'public' AND c.table_name = tbl
            ORDER BY c.ordinal_position
        LOOP
            EXECUTE format('SELECT COUNT(*) FROM %I WHERE %I IS NULL', tbl, col) INTO nulls;
            
            table_name := tbl;
            column_name := col;
            total_records := total;
            null_count := nulls;
            null_percentage := ROUND(100.0 * nulls / NULLIF(total, 0), 2);
            
            RETURN NEXT;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Execute NULL check
SELECT * FROM check_all_nulls()
WHERE null_count > 0
ORDER BY table_name, null_percentage DESC;


-- ==========================================
-- 5. TIME DIMENSION ANALYSIS
-- ==========================================

-- Monthly data overview
SELECT 
    COUNT(DISTINCT month) AS distinct_months,
    MIN(month) AS earliest_month,
    MAX(month) AS latest_month
FROM customer_transactions;

-- Monthly distribution
SELECT 
    month,
    COUNT(*) AS record_count,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT store_id) AS unique_stores
FROM customer_transactions
GROUP BY month
ORDER BY month;


-- ==========================================
-- 6. NUMERIC FIELD STATISTICS - TRANSACTIONS
-- ==========================================

-- Integer fields summary
WITH stats AS (
    SELECT 'customer_tenure_months' AS field, customer_tenure_months AS val FROM customer_transactions
    UNION ALL SELECT 'household_size', household_size FROM customer_transactions
    UNION ALL SELECT 'orders_count', orders_count FROM customer_transactions
    UNION ALL SELECT 'morning_orders', morning_orders FROM customer_transactions
    UNION ALL SELECT 'midday_orders', midday_orders FROM customer_transactions
    UNION ALL SELECT 'evening_orders', evening_orders FROM customer_transactions
    UNION ALL SELECT 'basket_size_unique', basket_size_unique FROM customer_transactions
)
SELECT 
    field,
    MIN(val) AS min_val,
    MAX(val) AS max_val,
    ROUND(AVG(val), 2) AS avg_val,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY val) AS median_val,
    COUNT(*) FILTER (WHERE val < 0) AS negative_count,
    COUNT(*) FILTER (WHERE val = 0) AS zero_count
FROM stats
GROUP BY field
ORDER BY field;

-- Financial fields summary
WITH stats AS (
    SELECT 'avg_unit_price' AS field, avg_unit_price AS val FROM customer_transactions
    UNION ALL SELECT 'items_value_sum', items_value_sum FROM customer_transactions
    UNION ALL SELECT 'month_subtotal', month_subtotal FROM customer_transactions
    UNION ALL SELECT 'month_discount', month_discount FROM customer_transactions
    UNION ALL SELECT 'month_tax', month_tax FROM customer_transactions
    UNION ALL SELECT 'month_total', month_total FROM customer_transactions
)
SELECT 
    field,
    MIN(val) AS min_val,
    MAX(val) AS max_val,
    ROUND(AVG(val), 2) AS avg_val,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY val) AS median_val,
    COUNT(*) FILTER (WHERE val < 0) AS negative_count,
    COUNT(*) FILTER (WHERE val = 0) AS zero_count
FROM stats
GROUP BY field
ORDER BY field;


-- ==========================================
-- 7. BUSINESS LOGIC CONSISTENCY
-- ==========================================

-- Orders count validation (morning + midday + evening = total)
SELECT 
    'Orders count consistency' AS check_name,
    COUNT(*) AS inconsistent_rows,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_transactions), 2) AS pct
FROM customer_transactions
WHERE orders_count != (morning_orders + midday_orders + evening_orders);

-- Inconsistent found
-- Pattern analysis for orders_count = 0 records

SELECT 
    customer_segment,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE orders_count != (morning_orders + midday_orders + evening_orders)) AS inconsistent_records,
    ROUND(100.0 * COUNT(*) FILTER (WHERE orders_count != (morning_orders + midday_orders + evening_orders)) / COUNT(*), 2) AS inconsistent_pct
FROM customer_transactions
GROUP BY customer_segment
ORDER BY inconsistent_pct DESC;

SELECT 
    'orders_count = 0 analysis' AS analysis_type,
    SUM(CASE WHEN morning_orders = 1 AND midday_orders = 0 AND evening_orders = 0 THEN 1 ELSE 0 END) AS only_morning,
    SUM(CASE WHEN morning_orders = 0 AND midday_orders = 1 AND evening_orders = 0 THEN 1 ELSE 0 END) AS only_midday,
    SUM(CASE WHEN morning_orders = 0 AND midday_orders = 0 AND evening_orders = 1 THEN 1 ELSE 0 END) AS only_evening,
    COUNT(*) AS total
FROM customer_transactions
WHERE orders_count = 0;

-- Financial calculation (subtotal - discount + tax = total)
SELECT 
    'Financial calculation' AS check_name,
    COUNT(*) AS inconsistent_rows,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_transactions), 2) AS pct
FROM customer_transactions
WHERE ABS(month_total - (month_subtotal - month_discount + month_tax)) > 0.01;

-- Discount validation
SELECT 
    'Discount > Subtotal' AS check_name,
    COUNT(*) AS problematic_rows,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_transactions), 2) AS pct
FROM customer_transactions
WHERE month_discount > month_subtotal;

-- Outlier detection using IQR method (1.5 * IQR)
WITH orders_stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY orders_count)::NUMERIC AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY orders_count)::NUMERIC AS q3,
        (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY orders_count) - 
         PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY orders_count))::NUMERIC AS iqr
    FROM customer_transactions
),
transaction_stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY month_total)::NUMERIC AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY month_total)::NUMERIC AS q3,
        (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY month_total) - 
         PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY month_total))::NUMERIC AS iqr
    FROM customer_transactions
),
price_stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_unit_price)::NUMERIC AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_unit_price)::NUMERIC AS q3,
        (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_unit_price) - 
         PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_unit_price))::NUMERIC AS iqr
    FROM customer_transactions
    WHERE avg_unit_price > 0
)
SELECT 
    'Orders count outliers' AS check_name,
    COUNT(*) AS outlier_count,
    (SELECT COUNT(*) FROM customer_transactions) AS total_records,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_transactions), 2) AS outlier_pct,
    MIN(orders_count) AS min_outlier,
    MAX(orders_count) AS max_outlier,
    ROUND((SELECT q1 - 1.5 * iqr FROM orders_stats), 2) AS lower_bound,
    ROUND((SELECT q3 + 1.5 * iqr FROM orders_stats), 2) AS upper_bound
FROM customer_transactions, orders_stats
WHERE orders_count < (q1 - 1.5 * iqr) OR orders_count > (q3 + 1.5 * iqr)
UNION ALL
SELECT 
    'Transaction amount outliers',
    COUNT(*),
    (SELECT COUNT(*) FROM customer_transactions),
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_transactions), 2),
    MIN(month_total),
    MAX(month_total),
    ROUND((SELECT q1 - 1.5 * iqr FROM transaction_stats), 2),
    ROUND((SELECT q3 + 1.5 * iqr FROM transaction_stats), 2)
FROM customer_transactions, transaction_stats
WHERE month_total < (q1 - 1.5 * iqr) OR month_total > (q3 + 1.5 * iqr)
UNION ALL
SELECT 
    'Unit price outliers',
    COUNT(*),
    (SELECT COUNT(*) FROM customer_transactions WHERE avg_unit_price > 0),
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_transactions WHERE avg_unit_price > 0), 2),
    MIN(avg_unit_price),
    MAX(avg_unit_price),
    ROUND((SELECT q1 - 1.5 * iqr FROM price_stats), 2),
    ROUND((SELECT q3 + 1.5 * iqr FROM price_stats), 2)
FROM customer_transactions, price_stats
WHERE avg_unit_price > 0 
  AND (avg_unit_price < (q1 - 1.5 * iqr) OR avg_unit_price > (q3 + 1.5 * iqr));

-- Customer tenure growth validation
WITH tenure_growth AS (
    SELECT 
        customer_id,
        MAX(customer_tenure_months) - MIN(customer_tenure_months) AS growth
    FROM customer_transactions
    GROUP BY customer_id
)
SELECT 
    'Customer tenure growth' AS check_name,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE growth <= 5) AS valid_growth,
    COUNT(*) FILTER (WHERE growth > 5) AS invalid_growth,
    MAX(growth) AS max_growth
FROM tenure_growth;


-- ==========================================
-- 8. CUSTOMER DEMOGRAPHICS ANALYSIS
-- ==========================================

-- Numeric field statistics
SELECT 
    'Age' AS field,
    MIN(age) AS min_val,
    MAX(age) AS max_val,
    ROUND(AVG(age), 2) AS avg_val,
    COUNT(*) FILTER (WHERE age < 18) AS flag_1,
    COUNT(*) FILTER (WHERE age > 100) AS flag_2
FROM customer_demographics
UNION ALL
SELECT 'Household Size', MIN(household_size), MAX(household_size), 
       ROUND(AVG(household_size), 2),
       COUNT(*) FILTER (WHERE household_size < 1),
       COUNT(*) FILTER (WHERE household_size > 10)
FROM customer_demographics
UNION ALL
SELECT 'Tenure Months', MIN(customer_tenure_months), MAX(customer_tenure_months),
       ROUND(AVG(customer_tenure_months), 2),
       COUNT(*) FILTER (WHERE customer_tenure_months < 0),
       COUNT(*) FILTER (WHERE customer_tenure_months > 120)
FROM customer_demographics;

-- Segment analysis
SELECT 
    customer_segment,
    COUNT(*) AS count,
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(household_size), 2) AS avg_household,
    ROUND(AVG(customer_tenure_months), 1) AS avg_tenure,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_loyalty_member) / COUNT(*), 2) AS loyalty_pct
FROM customer_demographics
GROUP BY customer_segment
ORDER BY customer_segment;

-- Income bucket distribution
SELECT 
    income_bucket,
    COUNT(*) AS count,
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_loyalty_member) / COUNT(*), 2) AS loyalty_pct
FROM customer_demographics
GROUP BY income_bucket
ORDER BY 
    CASE income_bucket
        WHEN '<50k' THEN 1
        WHEN '50-100k' THEN 2
        WHEN '100-150k' THEN 3
        WHEN '>150k' THEN 4
    END;


-- ==========================================
-- 9. STORE INFO ANALYSIS
-- ==========================================

-- Store metrics statistics
SELECT 
    'Store Size (sqft)' AS metric,
    MIN(store_size_sqft) AS min_val,
    MAX(store_size_sqft) AS max_val,
    ROUND(AVG(store_size_sqft), 0) AS avg_val,
    COUNT(*) FILTER (WHERE store_size_sqft < 5000) AS small,
    COUNT(*) FILTER (WHERE store_size_sqft > 50000) AS large
FROM store_info
UNION ALL
SELECT 'Employees', MIN(num_employees), MAX(num_employees),
       ROUND(AVG(num_employees), 0),
       COUNT(*) FILTER (WHERE num_employees < 10),
       COUNT(*) FILTER (WHERE num_employees > 200)
FROM store_info
UNION ALL
SELECT 'Daily Customers', MIN(avg_daily_customers), MAX(avg_daily_customers),
       ROUND(AVG(avg_daily_customers), 0),
       COUNT(*) FILTER (WHERE avg_daily_customers < 500),
       COUNT(*) FILTER (WHERE avg_daily_customers > 5000)
FROM store_info;

-- Geographic validation (Canada coordinates)
SELECT 
    'Latitude (41-84)' AS check_name,
    MIN(lat) AS min_val,
    MAX(lat) AS max_val,
    COUNT(*) FILTER (WHERE lat < 41 OR lat > 84) AS out_of_range
FROM store_info
UNION ALL
SELECT 'Longitude (-141 to -52)', MIN(lon), MAX(lon),
       COUNT(*) FILTER (WHERE lon < -141 OR lon > -52)
FROM store_info;

-- Store type analysis
SELECT 
    store_type,
    COUNT(*) AS store_count,
    ROUND(AVG(store_size_sqft), 0) AS avg_size,
    ROUND(AVG(num_employees), 1) AS avg_employees,
    ROUND(AVG(avg_daily_customers), 0) AS avg_daily_customers,
    ROUND(AVG(store_size_sqft::NUMERIC / NULLIF(num_employees, 0)), 0) AS sqft_per_emp
FROM store_info
GROUP BY store_type
ORDER BY store_type;

-- Provincial distribution
SELECT 
    province,
    COUNT(*) AS store_count
FROM store_info
GROUP BY province
ORDER BY store_count DESC;

-- Staffing efficiency check
SELECT 
    store_id,
    store_name,
    ROUND(store_size_sqft::NUMERIC / NULLIF(num_employees, 0), 0) AS sqft_per_emp,
    ROUND(avg_daily_customers::NUMERIC / NULLIF(num_employees, 0), 1) AS cust_per_emp,
    CASE 
        WHEN num_employees = 0 THEN 'ERROR: No employees'
        WHEN store_size_sqft::NUMERIC / num_employees < 200 THEN 'Overcrowded'
        WHEN store_size_sqft::NUMERIC / num_employees > 2000 THEN 'Under-staffed'
        WHEN avg_daily_customers::NUMERIC / num_employees > 100 THEN 'Under-staffed'
        ELSE 'Normal'
    END AS status
FROM store_info
WHERE num_employees = 0 
   OR store_size_sqft::NUMERIC / num_employees < 200
   OR store_size_sqft::NUMERIC / num_employees > 2000
   OR avg_daily_customers::NUMERIC / num_employees > 100
ORDER BY sqft_per_emp DESC NULLS LAST;


-- ==========================================
-- 10. DATA TYPE VERIFICATION
-- ==========================================

SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('customer_transactions', 'customer_demographics', 'store_info')
  AND column_name IN (
      'customer_tenure_months', 'household_size', 'orders_count', 
      'morning_orders', 'midday_orders', 'evening_orders',
      'basket_size_unique', 'avg_unit_price', 'items_value_sum',
      'month_subtotal', 'month_discount', 'month_tax', 'month_total',
      'age', 'lat', 'lon', 'store_size_sqft', 'num_employees', 'avg_daily_customers'
  )
ORDER BY table_name, column_name;


-- ==========================================
-- 11. SUMMARY REPORT
-- ==========================================

SELECT 
    'Total Records' AS metric,
    (SELECT COUNT(*) FROM customer_transactions)::TEXT AS value
UNION ALL
SELECT 'Unique Customers', COUNT(DISTINCT customer_id)::TEXT
FROM customer_transactions
UNION ALL
SELECT 'Unique Stores', COUNT(DISTINCT store_id)::TEXT
FROM customer_transactions
UNION ALL
SELECT 'Time Period', 
       MIN(month)::TEXT || ' to ' || MAX(month)::TEXT
FROM customer_transactions
UNION ALL
SELECT 'Total Customers', COUNT(*)::TEXT
FROM customer_demographics
UNION ALL
SELECT 'Total Stores', COUNT(*)::TEXT
FROM store_info;

-- ==========================================
-- END OF DATA QUALITY CHECKS
-- ==========================================