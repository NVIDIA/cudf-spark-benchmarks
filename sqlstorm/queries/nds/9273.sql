
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_profit AS customer_total_profit,
    cs.customer_count,
    ws.w_warehouse_id,
    ws.orders_count,
    ws.total_profit AS warehouse_total_profit
FROM 
    CustomerStats cs
JOIN 
    WarehouseStats ws ON cs.total_profit > ws.total_profit
WHERE 
    cs.total_profit > 10000 
ORDER BY 
    cs.total_profit DESC, ws.total_profit ASC
LIMIT 50;
