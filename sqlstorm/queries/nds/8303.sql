
WITH top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        c.c_customer_id IN (SELECT c_customer_id FROM top_customers)
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country
),
sales_summary AS (
    SELECT 
        sm.sm_type,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        sm.sm_type
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    ca.customer_count,
    ss.sm_type,
    ss.total_orders,
    ss.total_sales_profit
FROM 
    customer_addresses ca
JOIN 
    sales_summary ss ON ca.customer_count > 5
ORDER BY 
    ca.customer_count DESC, ss.total_sales_profit DESC;
