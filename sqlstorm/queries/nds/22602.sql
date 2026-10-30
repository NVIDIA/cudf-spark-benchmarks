
WITH RecursiveCTE AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
), AddressCounts AS (
    SELECT 
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state
), SalesStats AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2015 AND 2023
    GROUP BY 
        d.d_year
)
SELECT 
    r.customer_name,
    r.ca_city,
    r.ca_state,
    ac.address_count,
    ss.total_profit,
    ss.total_quantity,
    CASE 
        WHEN r.total_orders > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS customer_type
FROM 
    RecursiveCTE r
LEFT JOIN 
    AddressCounts ac ON r.ca_state = ac.ca_state
LEFT JOIN 
    SalesStats ss ON ss.total_profit IS NOT NULL
WHERE 
    r.ca_city IS NOT NULL
    AND r.ca_state IS NOT NULL
    AND (ss.total_profit IS NULL OR ss.total_quantity > 20)
ORDER BY 
    r.total_orders DESC, 
    r.customer_name
LIMIT 100;
