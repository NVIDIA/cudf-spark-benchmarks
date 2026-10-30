WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank_order
    FROM 
        customer_sales cs
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(tc.c_customer_sk) AS num_top_customers,
    AVG(tc.total_spent) AS avg_spent_top_customers
FROM 
    top_customers tc
JOIN customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE 
    tc.rank_order <= 10
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    avg_spent_top_customers DESC
LIMIT 5;