WITH sales_summary AS (
    SELECT 
        ws_item_sk AS item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451546  
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ss.total_quantity,
    ss.total_net_profit
FROM 
    sales_summary ss
JOIN 
    item i ON ss.item_sk = i.i_item_sk
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10;