
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_profit_generated
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
DailySales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_sales_price) AS daily_sales,
        SUM(ws.ws_net_profit) AS daily_profit
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_date
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_profit,
    ws.w_warehouse_name,
    ws.total_profit_generated,
    ds.daily_sales,
    ds.daily_profit
FROM 
    CustomerStats cs
LEFT JOIN 
    WarehouseStats ws ON ws.total_profit_generated > (SELECT AVG(total_profit) FROM CustomerStats)
LEFT JOIN 
    DailySales ds ON ds.daily_profit > (SELECT MAX(daily_profit) FROM DailySales WHERE daily_sales < (SELECT AVG(daily_sales) FROM DailySales))
WHERE 
    cs.total_orders > 10
ORDER BY 
    cs.total_profit DESC, cs.c_last_name;
