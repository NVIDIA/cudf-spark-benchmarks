
WITH customer_sales AS (
    SELECT c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name, 
           COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
           COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
           COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c_customer_id, 
           c_first_name, 
           c_last_name, 
           RANK() OVER (ORDER BY total_web_sales + total_catalog_sales + total_store_sales DESC) AS sales_rank
    FROM customer_sales
)
SELECT tc.c_customer_id, 
       tc.c_first_name, 
       tc.c_last_name,
       cs.total_web_sales,
       cs.total_catalog_sales,
       cs.total_store_sales,
       (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
       CASE 
           WHEN cs.total_web_sales IS NULL THEN 'no web sales'
           ELSE 'web sales present'
       END AS web_sales_status
FROM top_customers tc
JOIN customer_sales cs ON tc.c_customer_id = cs.c_customer_id
WHERE tc.sales_rank <= 10
ORDER BY total_sales DESC;
