
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_ship_mode_sk, ws_item_sk
),
sales_summary AS (
    SELECT 
        dd.d_date AS sale_date,
        sm.sm_ship_mode_id,
        rs.total_quantity,
        rs.total_net_profit
    FROM 
        ranked_sales rs
    JOIN 
        date_dim dd ON rs.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        ship_mode sm ON rs.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    sale_date,
    sm_ship_mode_id,
    total_quantity,
    total_net_profit
FROM 
    sales_summary
ORDER BY 
    sale_date, sm_ship_mode_id;
