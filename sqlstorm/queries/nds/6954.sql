
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        w.w_warehouse_id,
        c.c_birth_year,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_sold_date_sk, w.w_warehouse_id, c.c_birth_year, cd.cd_gender
)
SELECT 
    sd.w_warehouse_id,
    sd.c_birth_year,
    sd.cd_gender,
    AVG(sd.total_quantity) AS avg_quantity,
    SUM(sd.total_profit) AS total_profit,
    COUNT(sd.total_orders) AS total_orders
FROM 
    sales_data sd
GROUP BY 
    sd.w_warehouse_id, sd.c_birth_year, sd.cd_gender
ORDER BY 
    total_profit DESC, avg_quantity DESC
LIMIT 10;
