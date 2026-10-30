
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ws.ws_net_paid) AS total_spent, 
        COUNT(ws.ws_order_number) AS total_orders, 
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_handled, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
InventoryStats AS (
    SELECT 
        i.i_item_id, 
        AVG(inv.inv_quantity_on_hand) AS avg_quantity,
        SUM(i.i_current_price) AS total_inventory_value
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    cs.cd_gender, 
    cs.cd_marital_status, 
    cs.total_spent, 
    cs.total_orders, 
    ws.w_warehouse_id, 
    ws.total_orders_handled, 
    ws.total_profit, 
    is_.i_item_id, 
    is_.avg_quantity, 
    is_.total_inventory_value
FROM 
    CustomerStats cs
JOIN 
    WarehouseStats ws ON cs.total_orders > 0
JOIN 
    InventoryStats is_ ON is_.avg_quantity > 0
ORDER BY 
    cs.total_spent DESC, ws.total_profit DESC;
