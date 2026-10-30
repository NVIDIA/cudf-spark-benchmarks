
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(NULLIF(ca_suite_number, ''), '')) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_country) AS country_upper,
        LENGTH(TRIM(ca_zip)) AS zip_length
    FROM 
        customer_address
    WHERE 
        ca_state IN ('NY', 'CA', 'TX')
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_dep_count > 0
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_credit_rating,
    pa.full_address,
    pa.city_lower,
    pa.country_upper,
    pa.zip_length
FROM 
    customer_info ci
JOIN 
    processed_addresses pa ON ci.c_customer_sk = pa.ca_address_sk
ORDER BY 
    pa.zip_length DESC, ci.full_name ASC
LIMIT 100;
