
WITH customer_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
sales_statistics AS (
    SELECT 
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS sales_rank
    FROM customer_sales
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.total_sales,
        s.sales_rank
    FROM sales_statistics s
    JOIN customer c ON c.c_customer_id IN (SELECT c_customer_id FROM customer_sales WHERE total_web_sales IS NOT NULL)
    WHERE sales_rank <= 10
)
SELECT 
    tc.c_customer_id, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_sales
FROM top_customers tc
ORDER BY tc.total_sales DESC;
