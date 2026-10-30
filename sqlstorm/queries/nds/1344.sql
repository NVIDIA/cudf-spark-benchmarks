
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL 
        AND ca.ca_state = 'CA'
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state
    FROM 
        customer_info ci
    WHERE 
        ci.city_rank <= 10
),
sales_summary AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales 
    GROUP BY 
        ws_ship_customer_sk
),
final_summary AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        ss.total_profit,
        ss.total_orders,
        ss.avg_order_value,
        CASE 
            WHEN ss.total_profit IS NULL THEN 'No Sales'
            WHEN ss.total_profit > 1000 THEN 'High Value'
            ELSE 'Standard Value' 
        END AS customer_value_category
    FROM 
        top_customers tc
    LEFT JOIN 
        sales_summary ss ON tc.c_customer_sk = ss.ws_ship_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    COALESCE(f.total_profit, 0) AS total_profit,
    COALESCE(f.total_orders, 0) AS total_orders,
    COALESCE(f.avg_order_value, 0) AS avg_order_value,
    f.customer_value_category
FROM 
    final_summary f
ORDER BY 
    f.total_profit DESC, f.c_last_name, f.c_first_name;
