
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
return_data AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS total_returns
    FROM web_returns
    GROUP BY wr_item_sk
),
inventory_data AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(id.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL 
        ELSE (COALESCE(rd.total_return_amt, 0) / COALESCE(sd.total_sales, 0)) * 100 
    END AS return_percentage
FROM item i
LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN return_data rd ON i.i_item_sk = rd.wr_item_sk
LEFT JOIN inventory_data id ON i.i_item_sk = id.inv_item_sk
WHERE (i.i_current_price > 20 AND id.total_quantity_on_hand < 50) 
   OR (i.i_current_price <= 20 AND sd.total_orders > 100)
ORDER BY total_profit DESC;
