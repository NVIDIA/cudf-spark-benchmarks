
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        cs.c_customer_id AS customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS sales_rank
    FROM customer_sales cs
)
SELECT 
    tc.customer_id,
    tc.total_web_sales,
    tc.total_catalog_sales,
    tc.total_store_sales,
    tc.total_sales,
    tc.sales_rank
FROM top_customers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
