
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_net_profit
    FROM 
        ranked_sales rs
    WHERE 
        rs.rn <= 5
),
sales_summary AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        COALESCE(SUM(ts.ws_net_profit), 0) AS total_net_profit,
        COUNT(ts.ws_order_number) AS total_orders,
        AVG(ts.ws_quantity) AS avg_quantity
    FROM 
        item i
    LEFT JOIN 
        top_sales ts ON i.i_item_sk = ts.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
)
SELECT 
    ss.i_item_id,
    ss.i_product_name,
    ss.total_net_profit,
    ss.total_orders,
    ss.avg_quantity,
    CASE 
        WHEN ss.total_net_profit > 100000 THEN 'High Performer'
        WHEN ss.total_net_profit BETWEEN 50000 AND 100000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    sales_summary ss
WHERE 
    ss.avg_quantity > (SELECT AVG(ws.ws_quantity) FROM web_sales ws)
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10;
