
WITH customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_spent,
        DENSE_RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        customer_purchases cp
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No purchases'
        WHEN tc.total_spent < 100 THEN 'Low spender'
        WHEN tc.total_spent BETWEEN 100 AND 500 THEN 'Medium spender'
        ELSE 'High spender' 
    END AS spending_category,
    COALESCE(ROUND(AVG(ws.ws_net_profit), 2), 0) AS average_net_profit
FROM 
    top_customers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_spent
ORDER BY 
    total_spent DESC;
