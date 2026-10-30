
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.total_catalog_sales,
        (cs.total_store_sales + cs.total_web_sales + cs.total_catalog_sales) AS total_sales,
        DENSE_RANK() OVER (ORDER BY (cs.total_store_sales + cs.total_web_sales + cs.total_catalog_sales) DESC) AS sales_rank
    FROM customer_sales cs
),
income_bracket AS (
    SELECT 
        c.c_customer_sk,
        H.hd_income_band_sk,
        CASE 
            WHEN H.hd_income_band_sk BETWEEN 1 AND 5 THEN 'Low'
            WHEN H.hd_income_band_sk BETWEEN 6 AND 10 THEN 'Medium'
            ELSE 'High'
        END AS income_category
    FROM household_demographics H
    JOIN customer c ON H.hd_demo_sk = c.c_current_hdemo_sk
),
final_summary AS (
    SELECT 
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.total_sales,
        ib.income_category
    FROM sales_summary ss
    LEFT JOIN income_bracket ib ON ss.c_customer_sk = ib.c_customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_sales,
    fs.income_category,
    CASE 
        WHEN fs.total_sales IS NULL THEN 'No Sales'
        WHEN fs.total_sales = 0 THEN 'No Income'
        WHEN fs.total_sales < 200 THEN 'Below Average'
        WHEN fs.total_sales BETWEEN 200 AND 500 THEN 'Average'
        ELSE 'Above Average'
    END AS sales_performance,
    SUM(fs.total_sales) OVER () AS aggregate_sales,
    ROW_NUMBER() OVER (PARTITION BY fs.income_category ORDER BY fs.total_sales DESC) AS category_rank
FROM final_summary fs
LEFT JOIN income_bracket ib ON fs.c_customer_sk = ib.c_customer_sk
ORDER BY fs.total_sales DESC NULLS LAST
LIMIT 100;
