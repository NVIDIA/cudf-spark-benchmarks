
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
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
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
DateStats AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_ship_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_quantity,
    cs.total_net_profit AS customer_net_profit,
    cs.total_orders AS customer_orders,
    ws.w_warehouse_name,
    ws.total_quantity_sold,
    ws.total_net_profit AS warehouse_net_profit,
    ds.d_year,
    ds.d_month_seq,
    ds.total_orders AS monthly_orders,
    ds.total_net_profit AS monthly_net_profit
FROM 
    CustomerStats cs
JOIN 
    WarehouseStats ws ON cs.total_quantity > 0
JOIN 
    DateStats ds ON cs.total_orders > 0
WHERE 
    cs.total_net_profit > 1000
ORDER BY 
    ds.d_year DESC, ds.d_month_seq DESC, cs.total_net_profit DESC;
