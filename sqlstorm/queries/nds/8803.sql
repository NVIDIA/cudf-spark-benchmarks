WITH SalesAggregate AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-10-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-10-31')
    GROUP BY 
        w.w_warehouse_id
),
CustomerMetrics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
InventoryStatus AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        i.i_item_id
),
FinalReport AS (
    SELECT 
        a.w_warehouse_id,
        a.total_sales,
        a.order_count,
        a.avg_net_profit,
        c.customer_count,
        c.avg_purchase_estimate,
        i.total_quantity
    FROM 
        SalesAggregate a
    JOIN 
        CustomerMetrics c ON a.total_sales > 1000 
    JOIN 
        InventoryStatus i ON a.w_warehouse_id = (SELECT w_warehouse_id FROM warehouse WHERE w_warehouse_sk = 1) 
)
SELECT 
    *
FROM 
    FinalReport
ORDER BY 
    total_sales DESC, customer_count DESC;