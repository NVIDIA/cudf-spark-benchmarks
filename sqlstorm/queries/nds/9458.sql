
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459565 AND 2459965 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
ItemPerformance AS (
    SELECT 
        i.i_item_id,
        COUNT(ws.ws_order_number) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    ws.w_warehouse_id,
    ws.total_inventory,
    ip.i_item_id,
    ip.total_sales,
    ip.avg_sales_price,
    ip.avg_discount
FROM 
    CustomerSummary cs
JOIN 
    WarehouseSummary ws ON cs.total_spent > 1000 
JOIN 
    ItemPerformance ip ON cs.total_purchases > 2 
ORDER BY 
    cs.total_spent DESC, ws.total_inventory ASC, ip.total_sales DESC
LIMIT 100;
