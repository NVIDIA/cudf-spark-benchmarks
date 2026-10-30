
WITH string_operations AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        REGEXP_REPLACE(c.c_first_name, '[aeiou]', '*') AS masked_first_name,
        UPPER(c.c_last_name) AS upper_last_name,
        LOWER(c.c_birth_country) AS lower_country
    FROM 
        customer c
),
aggregated_data AS (
    SELECT 
        full_name,
        AVG(name_length) AS avg_name_length,
        COUNT(DISTINCT email_domain) AS unique_domains,
        COUNT(DISTINCT masked_first_name) AS unique_masked_first_names,
        COUNT(DISTINCT upper_last_name) AS unique_upper_last_names,
        COUNT(DISTINCT lower_country) AS unique_lower_countries
    FROM 
        string_operations
    GROUP BY 
        full_name
)
SELECT 
    full_name,
    avg_name_length,
    unique_domains,
    unique_masked_first_names,
    unique_upper_last_names,
    unique_lower_countries
FROM 
    aggregated_data
WHERE 
    avg_name_length > 20 
ORDER BY 
    avg_name_length DESC
LIMIT 100;
