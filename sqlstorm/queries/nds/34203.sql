
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) + COALESCE(SUM(cs.cs_net_profit), 0) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_ranked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
)
SELECT 
    sr.c_first_name,
    sr.c_last_name,
    sr.total_web_sales,
    sr.total_catalog_sales,
    sr.total_sales,
    CASE 
        WHEN sr.sales_rank <= 10 THEN 'Top 10 Customer'
        WHEN sr.sales_rank <= 50 THEN 'Top 50 Customer'
        ELSE 'Other Customer'
    END AS customer_segment
FROM sales_ranked sr
JOIN customer_demographics cd ON sr.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M' 
    AND cd.cd_purchase_estimate > 1000
ORDER BY sr.total_sales DESC;
