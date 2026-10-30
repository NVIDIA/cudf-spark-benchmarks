
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) AS total_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) DESC) AS sales_rank
    FROM customer_sales cs
    LEFT JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
income_distribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_sales) AS total_income 
    FROM household_demographics h
    JOIN sales_summary cs ON h.hd_demo_sk = cs.c_customer_sk
    GROUP BY h.hd_income_band_sk
)
SELECT 
    i.ib_income_band_sk,
    i.ib_lower_bound,
    i.ib_upper_bound,
    COALESCE(d.customer_count, 0) AS customer_count,
    COALESCE(d.total_income, 0) AS total_income,
    ROUND(COALESCE(d.total_income, 0) / NULLIF(d.customer_count, 0), 2) AS avg_income_per_customer
FROM income_band i
LEFT JOIN income_distribution d ON i.ib_income_band_sk = d.hd_income_band_sk
WHERE i.ib_lower_bound > 0
ORDER BY i.ib_income_band_sk;
