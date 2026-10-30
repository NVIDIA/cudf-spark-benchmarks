
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS formatted_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    ai.formatted_address,
    ai.address_count,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.customer_count
FROM 
    AddressInfo ai
JOIN 
    CustomerInfo ci ON ai.address_count > 50 AND ci.customer_count > 10
ORDER BY 
    ai.ca_city, 
    ai.ca_state, 
    ci.cd_gender;
