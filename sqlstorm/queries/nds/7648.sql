
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit_warehouse,
        COUNT(ws.ws_order_number) AS total_orders_warehouse
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_id,
    cs.total_net_profit,
    cs.total_orders,
    w.total_net_profit_warehouse,
    w.total_orders_warehouse,
    (cs.total_net_profit + COALESCE(w.total_net_profit_warehouse, 0)) AS combined_profit
FROM 
    CustomerSales cs
LEFT JOIN 
    WarehouseSales w ON cs.total_orders > 5
ORDER BY 
    combined_profit DESC
LIMIT 100;
