
WITH processed_customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_birth_country) AS birth_country,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        REPLACE(c.c_email_address, '@', '[at]') AS obfuscated_email
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_processing AS (
    SELECT 
        ca.ca_address_sk,
        TRIM(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
aggregated_data AS (
    SELECT 
        p.birth_country,
        p.gender,
        COUNT(*) AS customer_count,
        COUNT(DISTINCT a.ca_address_sk) AS unique_addresses
    FROM 
        processed_customer_data p
    JOIN 
        address_processing a ON p.c_customer_sk = a.ca_address_sk
    GROUP BY 
        p.birth_country, p.gender
)
SELECT 
    birth_country,
    gender,
    customer_count,
    unique_addresses,
    CONCAT('Total Customers: ', customer_count, ', Unique Addresses: ', unique_addresses) AS summary_info
FROM 
    aggregated_data
ORDER BY 
    birth_country, gender;
