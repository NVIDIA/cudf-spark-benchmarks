
WITH concatenated_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country) AS full_address
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_address_sk,
        a.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        concatenated_addresses a ON ca.ca_address_sk = a.ca_address_sk
)
SELECT 
    customer_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    COUNT(*) AS transaction_count
FROM 
    customer_info
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = customer_info.c_customer_sk
GROUP BY 
    customer_name, cd_gender, cd_marital_status, cd_education_status, full_address
ORDER BY 
    transaction_count DESC
LIMIT 10;
