
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.total_orders,
        c.total_profit,
        ROW_NUMBER() OVER (ORDER BY c.total_profit DESC) AS row_num
    FROM CustomerStats c
    WHERE c.total_orders > 5
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT inv.inv_item_sk) AS unique_items
    FROM warehouse w
    LEFT JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_orders,
    tc.total_profit,
    wi.w_warehouse_id,
    wi.total_inventory,
    wi.unique_items
FROM TopCustomers tc
LEFT JOIN WarehouseInfo wi ON tc.total_profit > (SELECT AVG(total_profit) FROM CustomerStats)
WHERE tc.row_num <= 10
ORDER BY tc.total_profit DESC;
