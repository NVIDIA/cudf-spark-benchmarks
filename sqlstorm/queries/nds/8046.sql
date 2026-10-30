
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        AVG(total_orders) AS avg_orders
    FROM 
        customer_sales
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders
    FROM 
        customer_sales cs
    JOIN 
        average_sales av ON cs.total_sales > av.avg_sales
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    hvc.total_sales,
    hvc.total_orders
FROM 
    high_value_customers hvc
JOIN 
    customer c ON hvc.c_customer_sk = c.c_customer_sk
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
