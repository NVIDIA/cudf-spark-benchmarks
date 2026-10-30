
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        i.i_category = 'Electronics'
    GROUP BY 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        rs.total_quantity,
        rs.total_net_profit
    FROM 
        ranked_sales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_profit <= 10
)
SELECT 
    tsa.i_item_id,
    tsa.i_product_name,
    tsa.total_quantity,
    tsa.total_net_profit,
    ca.ca_city,
    ca.ca_state
FROM 
    top_sales tsa
JOIN 
    customer c ON tsa.total_net_profit > c.c_birth_year
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    tsa.total_net_profit DESC;
