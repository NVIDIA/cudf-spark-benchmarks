
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS rank_quantity
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND ws.ws_net_paid_inc_tax > 0
        AND (i.i_brand IS NOT NULL OR (i.i_brand IS NULL AND i.i_color IS NOT NULL))
),
total_sales AS (
    SELECT 
        ws_item_sk AS item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        ranked_sales
    WHERE 
        rank_profit <= 5 OR rank_quantity <= 5
    GROUP BY 
        ws_item_sk
),
shipping_data AS (
    SELECT 
        ws.ws_item_sk,
        sm.sm_type,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_item_sk, sm.sm_type
),
final_report AS (
    SELECT 
        ts.item_sk,
        ts.total_quantity,
        ts.total_net_profit,
        sd.sm_type,
        sd.avg_profit,
        sd.order_count
    FROM 
        total_sales ts
    LEFT JOIN 
        shipping_data sd ON ts.item_sk = sd.ws_item_sk
)
SELECT 
    fr.item_sk,
    fr.total_quantity,
    fr.total_net_profit,
    COALESCE(fr.sm_type, 'N/A') AS shipping_method,
    (CASE 
        WHEN fr.total_net_profit IS NULL THEN 'No Profit Data'
        WHEN fr.total_net_profit > 1000 THEN 'High Profit'
        WHEN fr.total_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END) AS profit_category
FROM 
    final_report fr
WHERE 
    fr.total_quantity > 0
ORDER BY 
    fr.total_net_profit DESC;
