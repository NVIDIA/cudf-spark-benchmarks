
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state 
    FROM customer_address ca
),
sales_info AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_ship_customer_sk
),
combined_info AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        si.total_quantity,
        si.total_net_profit
    FROM customer_info ci
    LEFT JOIN address_info ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_ship_customer_sk
)
SELECT 
    full_name,
    c_email_address,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    ca_city,
    ca_state,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN total_net_profit > 1000 THEN 'High Value'
        WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM combined_info
WHERE cd_gender = 'F' 
ORDER BY total_net_profit DESC
LIMIT 100;
