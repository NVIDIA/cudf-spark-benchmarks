WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_web_sales,
    CASE 
        WHEN hvc.total_orders > 10 THEN 'High Frequency'
        WHEN hvc.total_orders BETWEEN 5 AND 10 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
    END AS order_frequency,
    COALESCE(hvc.total_web_sales, 0) AS net_sales
FROM 
    high_value_customers hvc
WHERE 
    hvc.sales_rank <= 50
ORDER BY 
    hvc.total_web_sales DESC;