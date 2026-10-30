
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit,
        i.i_item_desc,
        i.i_current_price,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        ranked_sales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    JOIN 
        web_sales ws ON rs.ws_item_sk = ws.ws_item_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        rs.profit_rank <= 10
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_profit,
    ts.i_item_desc,
    ts.i_current_price,
    ts.c_first_name,
    ts.c_last_name,
    ts.ca_city,
    ts.ca_state,
    ts.ca_country
FROM 
    top_sales ts
ORDER BY 
    ts.total_profit DESC;
