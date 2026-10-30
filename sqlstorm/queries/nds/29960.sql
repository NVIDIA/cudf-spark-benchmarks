
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        UPPER(c.c_email_address) AS email_uppercase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M' AND 
        ca.ca_state IN ('CA', 'NY')
),
aggregated_data AS (
    SELECT 
        ca_city,
        COUNT(*) AS customer_count,
        AVG(first_name_length) AS avg_first_name_length,
        AVG(last_name_length) AS avg_last_name_length
    FROM 
        customer_data 
    GROUP BY 
        ca_city
)
SELECT 
    ca_city,
    customer_count,
    avg_first_name_length,
    avg_last_name_length,
    CONCAT('Total customers from ', ca_city, ': ', customer_count) AS summary_text
FROM 
    aggregated_data
ORDER BY 
    customer_count DESC;
