
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        (COALESCE(SUM(ws.ws_net_profit), 0) + COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY (COALESCE(SUM(ws.ws_net_profit), 0) + COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0)) DESC) AS rank
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.rank,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS top_rank
    FROM 
        customer_sales cs
        JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    CASE 
        WHEN tc.top_rank <= 2 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    (SELECT COUNT(DISTINCT w.w_warehouse_sk) FROM warehouse w 
     WHERE w.w_warehouse_sq_ft > 10000) AS large_warehouses_count,
    (SELECT AVG(cdo.cd_dep_count) FROM customer_demographics cdo) AS avg_dependent_count
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
