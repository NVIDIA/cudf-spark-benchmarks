
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state
),
CityStats AS (
    SELECT 
        ca_city,
        ca_state,
        AVG(order_count) AS avg_order_count,
        SUM(total_spent) AS total_revenue
    FROM 
        CustomerOrders
    GROUP BY 
        ca_city, ca_state
),
TopCities AS (
    SELECT 
        ca_city, 
        ca_state, 
        avg_order_count, 
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) as rank
    FROM 
        CityStats
)
SELECT 
    ca_city, 
    ca_state, 
    avg_order_count, 
    total_revenue
FROM 
    TopCities
WHERE 
    rank <= 10
ORDER BY 
    total_revenue DESC;
