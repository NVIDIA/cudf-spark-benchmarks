
WITH processed_strings AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        TRIM(UPPER(c.c_email_address)) AS standardized_email,
        SUBSTRING(REPLACE(c.c_first_name, ' ', ''), 1, 5) AS short_first_name,
        LENGTH(TRIM(c.c_last_name)) AS last_name_length,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_description
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
summary AS (
    SELECT 
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(last_name_length) AS avg_last_name_length,
        COUNT(DISTINCT standardized_email) AS unique_emails,
        gender_description
    FROM 
        processed_strings
    GROUP BY 
        gender_description
)
SELECT 
    gender_description,
    total_customers,
    avg_last_name_length,
    unique_emails
FROM 
    summary
ORDER BY 
    gender_description;
