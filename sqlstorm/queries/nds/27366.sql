
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip
    FROM customer_address
),
GenderDetails AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status 
    FROM customer_demographics
),
CustomerInfo AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_email_address, 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM customer c
    JOIN GenderDetails cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT 
    ci.c_customer_sk,
    CONCAT(ci.c_first_name, ' ', ci.c_last_name) AS customer_name,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent
FROM CustomerInfo ci
LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.c_email_address, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    ci.full_address, 
    ci.ca_city, 
    ci.ca_state, 
    ci.ca_zip
ORDER BY total_spent DESC
LIMIT 100;
