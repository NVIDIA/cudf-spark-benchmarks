
WITH sales_summary AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
        AND cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'S'
    GROUP BY 
        dd.d_year, dd.d_month_seq
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS warehouse_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
final_summary AS (
    SELECT 
        s.d_year,
        s.d_month_seq,
        ws.w_warehouse_name,
        s.total_orders,
        s.total_quantity_sold,
        s.total_net_profit,
        ws.total_orders AS warehouse_orders,
        ws.warehouse_net_profit
    FROM 
        sales_summary s
    JOIN 
        warehouse_summary ws ON s.total_orders = ws.total_orders
)
SELECT 
    d_year,
    d_month_seq,
    w_warehouse_name,
    total_orders,
    total_quantity_sold,
    total_net_profit,
    warehouse_orders,
    warehouse_net_profit,
    CAST(total_net_profit / NULLIF(total_orders, 0) AS DECIMAL(10, 2)) AS avg_order_profit,
    CAST(warehouse_net_profit / NULLIF(warehouse_orders, 0) AS DECIMAL(10, 2)) AS avg_warehouse_profit
FROM 
    final_summary
ORDER BY 
    d_year, d_month_seq, w_warehouse_name;
