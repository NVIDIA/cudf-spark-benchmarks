
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS average_order_value,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.average_order_value
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    hvc.average_order_value,
    COALESCE(ci.hd_income_band_sk, 0) AS income_band,
    CASE 
        WHEN hvc.order_count > 5 THEN 'Frequent'
        WHEN hvc.order_count BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'Infrequent'
    END AS order_frequency
FROM 
    high_value_customers hvc
LEFT JOIN 
    household_demographics ci ON hvc.c_customer_sk = ci.hd_demo_sk
ORDER BY 
    hvc.total_sales DESC 
LIMIT 10;
