
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
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
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
sales_summary AS (
    SELECT 
        ts.ws_item_sk,
        COUNT(ts.ws_order_number) AS total_orders,
        SUM(ts.ws_quantity) AS total_units_sold,
        SUM(ts.ws_net_profit) AS total_net_profit
    FROM 
        top_sales ts
    GROUP BY 
        ts.ws_item_sk
)
SELECT 
    ss.ws_item_sk,
    COALESCE(i.total_quantity, 0) AS inventory_available,
    ss.total_orders,
    ss.total_units_sold,
    ss.total_net_profit,
    CASE 
        WHEN ss.total_net_profit IS NULL THEN 'No sales'
        WHEN ss.total_net_profit > 1000 THEN 'High Profit'
        WHEN ss.total_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    sales_summary ss
LEFT JOIN 
    inventory_check i ON ss.ws_item_sk = i.inv_item_sk
JOIN 
    item it ON ss.ws_item_sk = it.i_item_sk
WHERE 
    it.i_current_price IS NOT NULL
ORDER BY 
    ss.total_net_profit DESC;
