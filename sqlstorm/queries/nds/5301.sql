
WITH customer_stats AS (
    SELECT 
        cd_demo_sk,
        SUM(CASE WHEN c.c_current_cdemo_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_customers,
        AVG(CASE WHEN c.c_birth_year IS NOT NULL THEN 2023 - c.c_birth_year ELSE NULL END) AS avg_age,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk
),
sales_data AS (
    SELECT 
        ws_bill_cdemo_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_cdemo_sk
),
joined_data AS (
    SELECT 
        cs.cd_demo_sk,
        cs.total_customers,
        cs.avg_age,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(sd.avg_sales_price, 0.00) AS avg_sales_price
    FROM 
        customer_stats cs 
    LEFT JOIN 
        sales_data sd ON cs.cd_demo_sk = sd.ws_bill_cdemo_sk
)
SELECT 
    j.cd_demo_sk,
    j.total_customers,
    j.avg_age,
    j.total_orders,
    j.total_net_profit,
    j.avg_sales_price,
    CASE 
        WHEN j.total_net_profit > 10000 THEN 'High Value Customer'
        WHEN j.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_category
FROM 
    joined_data j
ORDER BY 
    j.total_net_profit DESC,
    j.total_orders DESC
LIMIT 100;
