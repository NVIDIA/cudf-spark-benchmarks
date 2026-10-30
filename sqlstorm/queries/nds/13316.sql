
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_profit,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM 
        sales_summary AS ss
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit
FROM 
    top_items AS ti
JOIN 
    item AS i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    ti.rank <= 10;
