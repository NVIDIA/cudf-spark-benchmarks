
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
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
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
), 
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_name
), 
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    ws.w_warehouse_id,
    ws.w_warehouse_name,
    ws.total_quantity_on_hand,
    ss.d_year,
    ss.total_sold_quantity,
    ss.total_sales_profit,
    cs.total_quantity,
    cs.total_net_profit
FROM 
    customer_summary cs
JOIN 
    warehouse_summary ws ON cs.total_quantity > 100
JOIN 
    sales_summary ss ON ss.total_sold_quantity > 5000
ORDER BY 
    cs.total_net_profit DESC, ss.total_sales_profit ASC
LIMIT 100;
