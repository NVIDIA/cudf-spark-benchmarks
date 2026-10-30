
WITH  sales_totals AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS sales_count,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_store_sk
    HAVING SUM(ss_sales_price) IS NOT NULL
), 
demographics_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
sales_by_gender AS (
    SELECT 
        da.cd_gender,
        st.total_sales,
        st.sales_count
    FROM demographics_analysis da
    JOIN sales_totals st ON da.c_customer_sk = st.ss_store_sk
)
SELECT 
    s.cd_gender,
    MAX(s.total_sales) AS max_sales,
    AVG(s.total_sales) AS avg_sales,
    SUM(s.sales_count) AS total_transactions
FROM sales_by_gender s
GROUP BY s.cd_gender
HAVING MAX(s.total_sales) > 1000
UNION ALL
SELECT 
    'ALL' AS overall_gender,
    SUM(s.total_sales) AS total_sales,
    AVG(s.total_sales) AS avg_sales,
    COUNT(*) AS total_transactions
FROM sales_by_gender s
WHERE s.total_sales IS NOT NULL
ORDER BY 1;
