
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales
    FROM customer AS c
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_store_sales + cs.total_web_sales + cs.total_catalog_sales AS total_sales,
        RANK() OVER (ORDER BY cs.total_store_sales + cs.total_web_sales + cs.total_catalog_sales DESC) AS sales_rank
    FROM customer_sales AS cs
    JOIN customer AS c ON cs.c_customer_sk = c.c_customer_sk
),
date_filter AS (
    SELECT d.d_date_sk
    FROM date_dim AS d
    WHERE d.d_date >= '2022-01-01' AND d.d_date <= '2022-12-31'
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.sales_rank
FROM sales_summary AS s
WHERE s.sales_rank <= 100 AND s.total_sales > 1000
AND EXISTS (
    SELECT 1
    FROM date_filter AS d
    INNER JOIN store_sales AS ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE ss.ss_customer_sk = s.c_customer_sk
)
ORDER BY s.total_sales DESC;
