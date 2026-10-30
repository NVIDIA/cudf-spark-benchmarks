
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        REPLACE(ca_city, 'City', 'Metropolis') AS updated_city,
        CONCAT(ca_state, ' - ', ca_zip) AS state_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.full_address,
        a.updated_city,
        a.state_zip
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        ProcessedAddresses a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.updated_city,
    ci.state_zip,
    COUNT(*) as customer_count
FROM 
    CustomerInfo ci
WHERE 
    ci.cd_gender = 'F'
GROUP BY 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.updated_city,
    ci.state_zip
HAVING 
    COUNT(*) > 1
ORDER BY 
    customer_count DESC;
