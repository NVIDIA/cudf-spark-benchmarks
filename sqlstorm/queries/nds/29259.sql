
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUBSTRING(c.c_birth_country, 1, 3) AS birth_country_subset,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    full_name,
    CONCAT('Gender: ', cd_gender, ', Marital Status: ', cd_marital_status) AS demographic_info,
    birth_country_subset,
    ca_city,
    ca_state,
    COUNT(*) OVER () AS total_customers
FROM 
    CustomerInfo
WHERE 
    rn = 1
    AND cd_purchase_estimate > 500
    AND (ca_city LIKE 'San%' OR ca_city LIKE 'Los%')
ORDER BY 
    cd_purchase_estimate DESC
LIMIT 50;
