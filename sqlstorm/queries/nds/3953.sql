
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.total_net_profit >= (
            SELECT 
                AVG(total_net_profit) 
            FROM 
                customer_sales
        )
),
average_order AS (
    SELECT 
        AVG(total_order_amount) AS average_order_value
    FROM (
        SELECT 
            ws.ws_order_number,
            SUM(ws.ws_net_paid) AS total_order_amount
        FROM 
            web_sales ws
        GROUP BY 
            ws.ws_order_number
    ) AS order_totals
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_net_profit,
    hvc.order_count,
    ao.average_order_value,
    CASE 
        WHEN hvc.order_count > 10 THEN 'Frequent Customer'
        WHEN hvc.order_count > 0 AND hvc.order_count <= 10 THEN 'Occasional Customer'
        ELSE 'No Orders'
    END AS customer_type
FROM 
    high_value_customers hvc,
    average_order ao
ORDER BY 
    hvc.total_net_profit DESC;
