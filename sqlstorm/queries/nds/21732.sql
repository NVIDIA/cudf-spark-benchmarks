
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM ranked_customers rc
    WHERE rc.rnk <= 5
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_id,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory
    FROM warehouse w
    LEFT JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id
),
sale_stats AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
),
combined_results AS (
    SELECT 
        tc.c_customer_id,
        ws.ws_item_sk,
        COALESCE(ws.total_quantity_sold, 0) AS quantity_sold,
        COALESCE(ws.total_profit, 0) AS total_profit
    FROM top_customers tc
    FULL OUTER JOIN sale_stats ws ON tc.c_customer_sk = ws.ws_item_sk
)
SELECT 
    cr.c_customer_id,
    SUM(cr.quantity_sold) AS total_sales,
    MAX(cr.total_profit) AS peak_profit,
    COUNT(cr.ws_item_sk) AS distinct_items_purchased,
    CASE 
        WHEN COUNT(cr.ws_item_sk) IS NULL THEN 'No Purchases'
        WHEN COUNT(cr.ws_item_sk) = 0 THEN 'No Purchases'
        ELSE 'Some Purchases'
    END AS purchase_status
FROM combined_results cr
GROUP BY cr.c_customer_id
HAVING SUM(cr.quantity_sold) > 0
ORDER BY peak_profit DESC, total_sales DESC
LIMIT 10;
