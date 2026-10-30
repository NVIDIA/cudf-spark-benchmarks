
WITH  ranked_sales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_sales_price, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_position
    FROM web_sales
    WHERE ws_sales_price > 0
), 
inventory_data AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
), 
customer_info AS (
    SELECT 
        c_customer_sk, 
        cd_marital_status, 
        cd_gender,
        DENSE_RANK() OVER (ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_purchase_estimate IS NOT NULL
), 
high_value_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        ci.purchase_rank
    FROM customer c
    JOIN customer_info ci ON c.c_customer_sk = ci.c_customer_sk
    WHERE ci.purchase_rank <= 10
)
SELECT 
    hc.c_customer_sk,
    hc.c_first_name,
    hc.c_last_name,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    AVG(ws.ws_net_profit) AS avg_profit,
    MAX(ws.ws_net_profit) AS max_profit,
    COALESCE(MAX(CASE WHEN rs.rank_position = 1 THEN rs.ws_sales_price END), 0) AS max_sales_price
FROM high_value_customers hc
LEFT JOIN web_sales ws ON hc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN ranked_sales rs ON ws.ws_item_sk = rs.ws_item_sk
LEFT JOIN inventory_data inv ON ws.ws_item_sk = inv.inv_item_sk
WHERE 
    ws.ws_sold_date_sk IS NOT NULL
    AND (inv.total_inventory IS NULL OR inv.total_inventory > 100)
GROUP BY 
    hc.c_customer_sk, 
    hc.c_first_name, 
    hc.c_last_name
HAVING 
    AVG(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_ship_date_sk IS NOT NULL)
ORDER BY 
    num_orders DESC,
    avg_profit DESC
LIMIT 10;
