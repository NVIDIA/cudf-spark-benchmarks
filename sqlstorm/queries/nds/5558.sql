
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ws.ws_quantity) AS total_purchases, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1999
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk, 
        w.w_warehouse_name, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
sales_summary AS (
    SELECT 
        ws.ws_ship_date_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.cd_gender, 
    cs.cd_marital_status, 
    ss.total_quantity_sold, 
    ss.total_net_profit, 
    wr.w_warehouse_name, 
    wr.total_inventory
FROM 
    customer_summary cs
JOIN 
    sales_summary ss ON ss.total_quantity_sold > 50
JOIN 
    warehouse_summary wr ON wr.total_inventory > 1000
ORDER BY 
    cs.total_spent DESC, 
    ss.total_net_profit DESC
LIMIT 100;
