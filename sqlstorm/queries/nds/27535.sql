
WITH EnhancedAddress AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        LENGTH(ca.ca_street_name) AS street_name_length,
        UPPER(ca.ca_city) AS city_upper,
        LOWER(ca.ca_country) AS country_lower
    FROM 
        customer_address ca
),
DistinctCustomers AS (
    SELECT 
        DISTINCT c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ea.full_address,
    ea.city_upper,
    ea.country_lower,
    dc.customer_name,
    dc.cd_gender,
    dc.cd_marital_status,
    COUNT(*) AS number_of_customers
FROM 
    EnhancedAddress ea
JOIN 
    DistinctCustomers dc ON ea.ca_address_sk = dc.c_customer_sk
GROUP BY 
    ea.full_address, ea.city_upper, ea.country_lower, dc.customer_name, dc.cd_gender, dc.cd_marital_status
ORDER BY 
    number_of_customers DESC
LIMIT 100;
