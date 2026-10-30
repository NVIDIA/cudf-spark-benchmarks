WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 AND 
        d.d_moy IN (11, 12) 
    GROUP BY 
        w.w_warehouse_id, c.c_customer_id
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        AVG(cs.cs_net_paid) AS avg_order_value
    FROM 
        catalog_sales cs
    JOIN 
        customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.w_warehouse_id,
    ss.c_customer_id,
    ss.total_profit,
    ss.total_orders,
    ss.total_items_sold,
    ds.order_count AS demographics_order_count,
    ds.avg_order_value
FROM 
    sales_summary ss
LEFT JOIN 
    demographics_summary ds ON ds.order_count IS NOT NULL
ORDER BY 
    ss.total_profit DESC, ss.total_orders DESC;