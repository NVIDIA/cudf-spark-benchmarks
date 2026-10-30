
WITH customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
inventory_info AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ss.total_quantity_sold,
    ss.total_net_profit,
    ii.total_quantity_on_hand,
    (CASE 
        WHEN ss.total_net_profit > 10000 THEN 'High Profit'
        WHEN ss.total_net_profit BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END) AS profit_category
FROM customer_info ci
JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
JOIN inventory_info ii ON ss.ws_item_sk = ii.inv_item_sk
WHERE ci.cd_gender = 'F'
AND ii.total_quantity_on_hand < 50
ORDER BY ss.total_net_profit DESC
LIMIT 100;
