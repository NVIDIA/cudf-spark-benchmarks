
WITH customer_data AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
benchmark_data AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    ca_city,
    ca_state,
    ca_country,
    total_net_profit,
    total_orders,
    CASE 
        WHEN total_net_profit > 10000 THEN 'High Value' 
        WHEN total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value_category,
    CONCAT(ca_city, ', ', ca_state, ' - ', ca_country) AS full_address
FROM 
    benchmark_data
ORDER BY 
    total_net_profit DESC, 
    full_name;
