
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales > 10000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS customer_value
    FROM 
        customer_sales cs
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'TX', 'NY')
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_sales,
    hvc.order_count,
    hvc.customer_value,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_addresses ca ON hvc.c_customer_sk = ca.ca_address_sk  
WHERE 
    hvc.total_sales > 2000
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
