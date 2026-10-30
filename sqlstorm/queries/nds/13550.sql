
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    ss.total_quantity,
    ss.total_sales,
    ss.total_profit
FROM 
    sales_summary ss
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
