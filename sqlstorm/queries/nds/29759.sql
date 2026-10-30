
WITH string_benchmark AS (
    SELECT 
        c.c_customer_id AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_lower,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_upper,
        SUBSTRING(CONCAT(c.c_first_name, ' ', c.c_last_name), 1, 10) AS name_substring,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), 'a', '@') AS replaced_name,
        CHAR_LENGTH(c.c_email_address) AS email_length,
        REGEXP_REPLACE(c.c_email_address, '@.*', '') AS email_username
    FROM 
        customer c
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
),
aggregated_benchmark AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(full_name_length) AS avg_full_name_length,
        AVG(email_length) AS avg_email_length
    FROM 
        string_benchmark
)
SELECT 
    total_customers,
    avg_full_name_length,
    avg_email_length
FROM 
    aggregated_benchmark
WHERE 
    total_customers > 0
ORDER BY 
    avg_full_name_length DESC;
