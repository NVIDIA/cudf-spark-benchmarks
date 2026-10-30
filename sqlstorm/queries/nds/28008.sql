
WITH processed_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(ca.ca_city, 'Unknown City') AS city,
        COALESCE(ca.ca_state, 'Unknown State') AS state,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, full_name, city, state
),
ranked_data AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM processed_data
)
SELECT 
    full_name,
    city,
    state,
    total_orders,
    total_spent,
    spending_rank
FROM ranked_data
WHERE spending_rank <= 10
ORDER BY total_spent DESC;
