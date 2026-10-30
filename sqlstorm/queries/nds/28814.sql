
WITH CONCATENATED_ADDRESSES AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END, 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address
    FROM 
        customer_address
),
CUSTOMER_INFO AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CONCATENATED_ADDRESSES ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ADDRESS_COUNT AS (
    SELECT 
        full_address,
        COUNT(*) AS customer_count
    FROM 
        CUSTOMER_INFO
    GROUP BY 
        full_address
)
SELECT 
    ac.full_address, 
    ac.customer_count,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status
FROM 
    ADDRESS_COUNT ac
JOIN 
    CUSTOMER_INFO ci ON ac.full_address = ci.full_address
WHERE 
    ac.customer_count > 1
ORDER BY 
    ac.customer_count DESC, 
    ci.full_name;
