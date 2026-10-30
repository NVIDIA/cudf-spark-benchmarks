WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_education_status IN ('Bachelors', 'Masters', 'PhD')
        AND ws.ws_sold_date_sk BETWEEN 2458849 AND 2459195  
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS warehouse_total_net_profit,
        AVG(ws.ws_list_price) AS avg_item_price
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.total_net_profit,
    cs.total_orders,
    ws.warehouse_total_net_profit,
    ws.avg_item_price
FROM 
    CustomerSales cs
JOIN 
    WarehouseStats ws ON cs.total_orders = ws.total_orders
WHERE 
    cs.total_net_profit > 5000  
ORDER BY 
    cs.total_net_profit DESC;