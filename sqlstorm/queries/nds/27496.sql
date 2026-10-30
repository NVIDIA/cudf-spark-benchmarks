
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_demographics_processed AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        LOWER(cd_education_status) AS education,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
customer_with_address AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        d.gender,
        d.cd_marital_status,
        d.education
    FROM 
        customer c
    JOIN 
        processed_addresses a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        customer_demographics_processed d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    c.full_address,
    c.ca_city,
    c.ca_state,
    c.ca_zip,
    c.ca_country,
    c.gender,
    c.cd_marital_status,
    c.education
FROM 
    customer_with_address c
WHERE 
    c.ca_state = 'CA'
    AND c.education LIKE '%university%'
ORDER BY 
    c.ca_city, 
    c.ca_zip;
