
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_name, d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
composite_summary AS (
    SELECT 
        s.w_warehouse_name,
        c.cd_gender,
        s.total_quantity_sold,
        c.total_quantity,
        s.total_net_profit,
        c.total_net_profit,
        (s.total_net_profit + c.total_net_profit) AS combined_net_profit
    FROM 
        sales_summary s
    JOIN 
        customer_summary c ON s.total_quantity_sold > 0 AND c.total_quantity > 0
)
SELECT 
    w_warehouse_name AS warehouse_name,
    cd_gender,
    total_quantity_sold,
    total_quantity,
    combined_net_profit
FROM 
    composite_summary
WHERE 
    combined_net_profit > 1000
ORDER BY 
    combined_net_profit DESC;
