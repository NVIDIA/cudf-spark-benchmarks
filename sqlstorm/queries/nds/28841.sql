
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        ca.ca_city AS city,
        ca.ca_state AS state,
        LOWER(c.c_email_address) AS email,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        ci.full_name,
        ci.gender,
        ci.city,
        ci.state,
        ci.email,
        ci.marital_status,
        ci.education_status,
        COALESCE(si.total_spent, 0) AS total_spent,
        COALESCE(si.total_orders, 0) AS total_orders
    FROM customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    gender,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS average_spent,
    AVG(total_orders) AS average_orders,
    MAX(total_spent) AS max_spent,
    MIN(total_spent) AS min_spent
FROM combined_info
GROUP BY gender
ORDER BY customer_count DESC;
