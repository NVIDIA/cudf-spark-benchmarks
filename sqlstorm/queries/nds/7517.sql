
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_sales_price) AS total_spent,
        AVG(COALESCE(cs.cs_sales_price, 0)) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk = ss.ss_store_sk AND s.s_state = 'CA')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
warehouse_stats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE 
        w.w_gmt_offset < -7
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    ws.total_profit,
    ws.total_sales
FROM 
    customer_stats cs
JOIN 
    warehouse_stats ws ON cs.total_orders > 0 AND ws.total_sales > 50
ORDER BY 
    cs.total_spent DESC, ws.total_profit DESC
LIMIT 100;
