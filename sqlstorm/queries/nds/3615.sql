
WITH recent_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        RANK() OVER (ORDER BY rs.total_net_profit DESC) AS profit_rank
    FROM 
        recent_sales rs
    WHERE 
        rs.total_quantity > 100
)
SELECT 
    ti.ws_item_sk,
    i.i_item_desc,
    i.i_current_price,
    ti.total_quantity,
    ti.profit_rank
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN 
    promotion p ON i.i_item_sk = p.p_item_sk AND p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
WHERE 
    ti.profit_rank <= 10
    AND (i.i_current_price IS NOT NULL OR i.i_wholesale_cost IS NOT NULL)
ORDER BY 
    ti.profit_rank;
