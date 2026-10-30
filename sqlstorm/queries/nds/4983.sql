
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        SUM(cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS grand_total,
        CASE 
            WHEN SUM(cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) > 1000 THEN 'High Value'
            WHEN SUM(cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_sales cs
    GROUP BY 
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_web_sales, cs.total_catalog_sales, cs.total_store_sales
    HAVING 
        SUM(cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) > 0
)
SELECT 
    customer_value, 
    COUNT(*) AS customer_count,
    AVG(grand_total) AS average_spent,
    MAX(grand_total) AS max_spent,
    MIN(grand_total) AS min_spent
FROM 
    sales_summary
GROUP BY 
    customer_value
ORDER BY 
    customer_value DESC;
