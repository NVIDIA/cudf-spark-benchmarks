
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(NULLIF(ca_suite_number, ''), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        CASE 
            WHEN ca_country LIKE '%United States%' THEN 'Domestic'
            ELSE 'International'
        END AS address_type
    FROM customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    pi.full_address,
    pi.ca_city,
    pi.ca_state,
    pi.ca_zip,
    pi.address_type,
    COALESCE(ss.total_spent, 0) AS total_spent,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM customer_info ci
LEFT JOIN processed_addresses pi ON ci.c_customer_sk = pi.ca_address_sk
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE ci.cd_purchase_estimate > 1000
ORDER BY total_spent DESC, ci.full_name;
