
WITH customer_info AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        c.c_current_cdemo_sk AS ws_bill_customer_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS average_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
demographics_and_sales AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.cd_dep_count,
        ci.cd_dep_employed_count,
        ci.cd_dep_college_count,
        COALESCE(sd.total_spent, 0) AS total_spent,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.average_order_value, 0) AS average_order_value
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.ws_bill_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ca_city,
    ca_state,
    ROUND(AVG(total_spent), 2) AS avg_spent,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    COUNT(DISTINCT full_name) AS customer_count,
    COUNT(DISTINCT CASE WHEN cd_marital_status = 'M' THEN full_name END) AS married_count
FROM demographics_and_sales
GROUP BY ca_city, ca_state
ORDER BY avg_spent DESC
LIMIT 10;
