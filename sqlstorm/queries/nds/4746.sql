
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) - COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) AS sales_difference
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_spenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > 1000
),
repeat_customers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 1
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.sales_difference,
    CASE 
        WHEN hs.total_spent IS NOT NULL THEN 'High Spender'
        ELSE 'Regular Customer'
    END AS customer_type,
    CASE 
        WHEN rc.order_count IS NOT NULL THEN 'Repeat Customer'
        ELSE 'New Customer'
    END AS customer_status
FROM 
    customer_sales cs
LEFT JOIN 
    high_spenders hs ON cs.c_customer_sk = hs.c_customer_sk
LEFT JOIN 
    repeat_customers rc ON cs.c_customer_sk = rc.c_customer_sk
WHERE 
    cs.total_web_sales > 0 OR cs.total_catalog_sales > 0
ORDER BY 
    cs.sales_difference DESC
LIMIT 50;
