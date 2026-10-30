
WITH customer_orders AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_country
),
top_customers AS (
    SELECT 
        full_name, 
        ca_city, 
        ca_state, 
        ca_country, 
        order_count,
        RANK() OVER (ORDER BY order_count DESC) AS rank
    FROM 
        customer_orders
)
SELECT 
    full_name, 
    ca_city, 
    ca_state, 
    ca_country, 
    order_count
FROM 
    top_customers
WHERE 
    rank <= 10
ORDER BY 
    order_count DESC;
