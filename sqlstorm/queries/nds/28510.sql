WITH Recap AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') 
        AND ws.ws_sold_date_sk > 2500000 
    GROUP BY 
        c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
)
SELECT 
    full_name, 
    ca_city, 
    ca_state,
    total_orders,
    total_spent,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent > 500 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    Recap
WHERE 
    total_orders > 5
ORDER BY 
    total_spent DESC
LIMIT 10;