
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        AVG(ws.ws_net_profit) AS avg_web_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS total_items_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_sales,
        AVG(ws.ws_net_profit) AS avg_sales_profit
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    ws.w_warehouse_name,
    cs.total_web_orders,
    cs.total_web_sales,
    cs.avg_web_profit,
    ws.total_items_sold,
    ws.total_sales_sales,
    ws.avg_sales_profit
FROM 
    CustomerStats cs
JOIN 
    WarehouseStats ws ON cs.total_web_orders > 0 AND cs.total_web_sales > 0
ORDER BY 
    cs.total_web_sales DESC, ws.total_sales_sales DESC
LIMIT 100;
