
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
income_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales
    FROM 
        household_demographics hd
    JOIN 
        customer_sales cs ON hd.hd_demo_sk = cs.c_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(income_summary.customer_count, 0) AS customer_count,
    COALESCE(income_summary.total_web_sales, 0) AS total_web_sales,
    COALESCE(income_summary.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(income_summary.total_store_sales, 0) AS total_store_sales
FROM 
    income_band ib
LEFT JOIN 
    income_summary ON ib.ib_income_band_sk = income_summary.hd_income_band_sk
WHERE 
    ib.ib_lower_bound IS NOT NULL
ORDER BY 
    ib.ib_lower_bound;
