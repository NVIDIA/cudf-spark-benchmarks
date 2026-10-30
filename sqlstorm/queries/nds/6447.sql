
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_name, d.d_year
), customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity_purchased,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.w_warehouse_name,
    ss.d_year,
    ss.total_quantity_sold,
    ss.total_net_paid,
    cs.c_customer_id,
    cs.total_quantity_purchased,
    cs.total_spent
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.total_quantity_sold > 100 AND cs.total_quantity_purchased > 50
ORDER BY 
    ss.d_year DESC, ss.total_net_paid DESC
LIMIT 100;
