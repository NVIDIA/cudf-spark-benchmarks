
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
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS total_sales
    FROM
        customer_sales cs
),
income_bracket AS (
    SELECT
        cd.cd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
),
final_report AS (
    SELECT
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.web_sales,
        ss.catalog_sales,
        ss.store_sales,
        ss.total_sales,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        sales_summary ss
    LEFT JOIN income_bracket ib ON ss.c_customer_sk = ib.cd_demo_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.web_sales,
    f.catalog_sales,
    f.store_sales,
    f.total_sales,
    f.ib_lower_bound,
    f.ib_upper_bound,
    CASE 
        WHEN f.total_sales > 1000 THEN 'High'
        WHEN f.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    final_report f
WHERE 
    f.web_sales IS NOT NULL OR f.catalog_sales IS NOT NULL OR f.store_sales IS NOT NULL
ORDER BY 
    f.total_sales DESC
LIMIT 100;
