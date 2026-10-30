
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LOWER(c.c_email_address) AS lower_email
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Counts AS (
    SELECT 
        ci.full_name,
        ci.lower_email,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM CustomerInfo ci
    LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ci.full_name, ci.lower_email, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status
),
Filtered AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent > 1000 THEN 'High Value'
            WHEN total_spent BETWEEN 501 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM Counts
)
SELECT 
    customer_value_segment,
    cd_gender,
    cd_marital_status,
    COUNT(*) AS number_of_customers,
    AVG(total_spent) AS avg_spent,
    MAX(total_orders) AS max_orders,
    MIN(total_orders) AS min_orders
FROM Filtered
GROUP BY customer_value_segment, cd_gender, cd_marital_status
ORDER BY customer_value_segment, cd_gender;
