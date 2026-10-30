
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(ca_zip) AS zip_length,
        REPLACE(LOWER(ca_country), ' ', '_') AS modified_country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        EXTRACT(YEAR FROM CURRENT_DATE) - (c.c_birth_year + (c.c_birth_month * 30 + c.c_birth_day) / 365.25) AS age,
        cbd.full_address,
        cbd.city_length,
        cbd.state_length,
        cbd.zip_length,
        cbd.modified_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses cbd ON c.c_current_addr_sk = cbd.ca_address_sk
)
SELECT 
    ci.customer_full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.age,
    ci.full_address,
    ci.city_length,
    ci.state_length,
    ci.zip_length,
    ci.modified_country
FROM 
    customer_info ci
WHERE 
    ci.cd_gender = 'F' AND 
    ci.age BETWEEN 30 AND 50
ORDER BY 
    ci.city_length DESC, ci.state_length DESC, ci.zip_length DESC;
