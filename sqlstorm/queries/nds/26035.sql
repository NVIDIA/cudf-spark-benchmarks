
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, full_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country
),
aggregate_info AS (
    SELECT 
        ca_state,
        COUNT(*) AS customer_count,
        SUM(total_orders) AS total_orders,
        SUM(total_spent) AS total_spent
    FROM customer_info
    GROUP BY ca_state
)
SELECT 
    a.ca_state,
    a.customer_count,
    a.total_orders,
    a.total_spent,
    ROUND(a.total_spent / NULLIF(a.customer_count, 0), 2) AS avg_spent_per_customer
FROM aggregate_info a
WHERE a.customer_count > 1
ORDER BY avg_spent_per_customer DESC
LIMIT 10;
