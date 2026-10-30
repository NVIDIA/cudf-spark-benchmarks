
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
        ca.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)

SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ss.total_spent,
    ss.total_orders,
    CASE 
        WHEN ss.total_spent IS NULL THEN 'No Sales'
        WHEN ss.total_spent > 1000 THEN 'High Roller'
        WHEN ss.total_spent BETWEEN 500 AND 1000 THEN 'Regular Customer'
        ELSE 'Casual Shopper'
    END AS customer_category
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.customer_sk
WHERE ci.ca_state = 'NY'
ORDER BY total_spent DESC, full_name;
