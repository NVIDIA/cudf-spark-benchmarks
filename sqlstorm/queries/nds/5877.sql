
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022 
        AND d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        w.w_warehouse_name
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
final_result AS (
    SELECT 
        ss.w_warehouse_name,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_net_profit,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.total_profit
    FROM 
        sales_summary ss
    JOIN 
        customer_info ci ON ci.total_profit > 0
)
SELECT 
    fr.w_warehouse_name,
    fr.total_quantity,
    fr.total_sales,
    fr.avg_net_profit,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_education_status,
    fr.total_profit
FROM 
    final_result fr
ORDER BY 
    fr.total_sales DESC, fr.total_profit DESC
LIMIT 100;
