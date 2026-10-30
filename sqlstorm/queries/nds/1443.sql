
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy = 10
        )
    GROUP BY 
        ws.ws_ship_customer_sk
),
final_data AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        sd.total_net_profit,
        sd.total_orders,
        COALESCE(cd.gender_rank, 0) AS gender_rank
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_data sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.total_net_profit,
    f.total_orders,
    CASE 
        WHEN f.total_net_profit IS NULL THEN 'No Sales'
        WHEN f.total_net_profit >= 1000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_value,
    COUNT(f.gender_rank) OVER (PARTITION BY f.cd_gender) AS gender_count,
    RANK() OVER (ORDER BY f.total_net_profit DESC) AS profit_rank
FROM 
    final_data f
WHERE 
    f.total_orders > 0 OR f.gender_rank > 0
ORDER BY 
    f.total_net_profit DESC, 
    f.c_last_name, 
    f.c_first_name;
