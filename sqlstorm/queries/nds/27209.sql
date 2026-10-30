
WITH Customer_Average_Spending AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
High_Value_Customers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        c.full_name,
        CASE 
            WHEN total_spent > 10000 THEN 'High Value'
            WHEN total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        Customer_Average_Spending AS c
)
SELECT 
    hvc.customer_id,
    hvc.full_name,
    hvc.customer_value_segment,
    COUNT(ws.ws_order_number) AS number_of_orders,
    AVG(ws.ws_sales_price) AS average_order_value,
    MAX(ws.ws_sales_price) AS max_order_value,
    MIN(ws.ws_sales_price) AS min_order_value,
    SUM(ws.ws_ext_sales_price) AS total_spent
FROM 
    High_Value_Customers AS hvc
JOIN 
    web_sales AS ws ON hvc.customer_id = ws.ws_bill_customer_sk
GROUP BY 
    hvc.customer_id, hvc.full_name, hvc.customer_value_segment
ORDER BY 
    total_spent DESC;
