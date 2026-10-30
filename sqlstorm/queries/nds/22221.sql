
WITH customer_stats AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(ws.ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
      AND c.c_birth_month IS NOT NULL
      AND c.c_birth_day IS NOT NULL
      AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status IN ('M', 'S'))
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT cs.c_customer_sk,
           cs.c_first_name,
           cs.c_last_name,
           cs.total_profit,
           cs.order_count
    FROM customer_stats cs
    WHERE cs.rank_profit <= 10
),
warehouse_info AS (
    SELECT w.w_warehouse_sk, 
           COUNT(inv.inv_quantity_on_hand) AS total_inventory,
           AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
high_inventory_warehouses AS (
    SELECT w.w_warehouse_sk,
           wi.total_inventory,
           wi.avg_inventory
    FROM warehouse w
    JOIN warehouse_info wi ON w.w_warehouse_sk = wi.w_warehouse_sk
    WHERE wi.avg_inventory > 50
),
final_report AS (
    SELECT tc.c_first_name,
           tc.c_last_name,
           COUNT(DISTINCT hw.w_warehouse_sk) AS warehouse_count,
           MAX(hw.avg_inventory) AS highest_avg_inventory
    FROM top_customers tc
    LEFT JOIN high_inventory_warehouses hw ON tc.c_customer_sk = hw.w_warehouse_sk
    GROUP BY tc.c_first_name, tc.c_last_name
)
SELECT fr.c_first_name,
       fr.c_last_name,
       COALESCE(fr.warehouse_count, 0) AS warehouse_count,
       CASE 
           WHEN fr.highest_avg_inventory IS NULL THEN 'No Inventory'
           ELSE CAST(fr.highest_avg_inventory AS VARCHAR(255))
       END AS highest_avg_inventory_string
FROM final_report fr
ORDER BY fr.c_last_name, fr.c_first_name;
