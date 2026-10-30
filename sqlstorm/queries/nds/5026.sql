
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS store_sales
    FROM 
        customer_sales cs
)
SELECT 
    c.c_customer_id AS customer_id,
    s.web_sales,
    s.catalog_sales,
    s.store_sales,
    (s.web_sales + s.catalog_sales + s.store_sales) AS total_sales
FROM 
    sales_summary s
JOIN customer_sales c ON c.c_customer_id = s.c_customer_id
WHERE 
    (s.web_sales + s.catalog_sales + s.store_sales) > 0
ORDER BY 
    total_sales DESC
LIMIT 10;
