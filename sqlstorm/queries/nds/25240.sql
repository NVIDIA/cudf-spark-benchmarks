
WITH processed_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CONCAT('US-', ca.ca_zip) AS formatted_zip,
        REGEXP_REPLACE(c.c_email_address, '@.*', '@example.com') AS anonymized_email,
        LENGTH(c.c_first_name || ' ' || c.c_last_name) AS name_length,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_purchase_estimate > 1000
),
aggregated_data AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS customer_count,
        AVG(name_length) AS avg_name_length,
        AVG(email_length) AS avg_email_length
    FROM 
        processed_data
    GROUP BY 
        ca_city, 
        ca_state
)
SELECT 
    ca_city,
    ca_state,
    customer_count,
    avg_name_length,
    avg_email_length,
    CONCAT('The average name length for customers in ', ca_city, ', ', ca_state, ' is ', ROUND(avg_name_length, 2), ' characters.') AS name_length_message
FROM 
    aggregated_data
ORDER BY 
    customer_count DESC
LIMIT 10;
