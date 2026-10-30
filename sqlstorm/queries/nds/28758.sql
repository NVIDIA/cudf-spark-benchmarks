WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', TRIM(ca_suite_number)) END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        d.d_date AS birth_date,
        cd.cd_gender,
        CONCAT(cd.cd_marital_status, ' - ', cd.cd_education_status) AS demographics
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    a.full_address,
    c.full_name,
    c.cd_gender,
    c.demographics,
    s.total_quantity,
    s.total_profit,
    s.order_count
FROM AddressParts a
JOIN CustomerDetails c ON a.ca_address_sk = c.c_customer_sk  
JOIN SalesData s ON s.ws_item_sk = c.c_customer_sk  
WHERE a.ca_state = 'CA'
ORDER BY total_profit DESC
LIMIT 50;