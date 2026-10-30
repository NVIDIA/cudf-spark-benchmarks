
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
customer_benchmark AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        COALESCE(sd.total_spent, 0) AS total_spent,
        COALESCE(sd.total_orders, 0) AS total_orders,
        CASE 
            WHEN COALESCE(sd.total_spent, 0) >= 1000 THEN 'High Spender'
            WHEN COALESCE(sd.total_spent, 0) BETWEEN 500 AND 999 THEN 'Medium Spender'
            ELSE 'Low Spender'
        END AS spending_category
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ca_state,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS average_spent,
    MAX(total_orders) AS max_orders,
    spending_category
FROM customer_benchmark
GROUP BY ca_state, spending_category
ORDER BY ca_state, spending_category;
