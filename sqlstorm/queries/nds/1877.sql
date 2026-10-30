
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank = 1
)
SELECT 
    ca.ca_city,
    SUM(ts.ws_quantity) AS total_quantity,
    SUM(ts.ws_net_profit) AS total_profit,
    COUNT(DISTINCT c.c_customer_id) AS num_customers
FROM 
    TopSales ts
JOIN 
    customer c ON ts.ws_item_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store s ON c.c_current_addr_sk = s.s_store_sk
LEFT JOIN 
    date_dim dd ON ts.ws_order_number = dd.d_date_sk
WHERE 
    (s.s_city = 'Seattle' OR ca.ca_city = 'Seattle') 
    AND (c.c_birth_year IS NOT NULL AND c.c_birth_year > 1980)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ts.ws_net_profit) > 1000 
ORDER BY 
    total_profit DESC
LIMIT 10;
