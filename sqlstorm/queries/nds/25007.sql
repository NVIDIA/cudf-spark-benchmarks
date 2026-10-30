
WITH customer_details AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
        CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) END, 
        ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        MIN(ws_sold_date_sk) AS first_order_date,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_spent, 0) AS total_spent,
    ss.first_order_date,
    ss.last_order_date
FROM customer_details cd
LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.customer_id
WHERE LENGTH(cd.full_name) > 15 
ORDER BY ss.total_spent DESC, cd.full_name ASC
LIMIT 100;
