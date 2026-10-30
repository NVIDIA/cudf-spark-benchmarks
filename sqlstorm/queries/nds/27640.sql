
WITH String_Benchmark AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(c.c_email_address, '@example.com', '@test.com') AS modified_email,
        UPPER(c.c_first_name || ' ' || c.c_last_name) AS upper_case_full_name,
        LENGTH(c.c_email_address) AS email_length,
        LEFT(c.c_last_name, 5) AS last_name_prefix,
        RIGHT(c.c_first_name, 3) AS first_name_suffix,
        SUBSTR(c.c_last_name, 1, 10) AS truncated_last_name,
        CASE 
            WHEN c.c_birth_month IS NOT NULL THEN CONCAT(CAST(c.c_birth_month AS STRING), '/', CAST(c.c_birth_day AS STRING))
            ELSE 'N/A' 
        END AS birth_date_string
    FROM 
        customer c
    WHERE 
        c.c_customer_id IS NOT NULL
)
SELECT 
    full_name,
    modified_email,
    upper_case_full_name,
    email_length,
    last_name_prefix,
    first_name_suffix,
    truncated_last_name,
    birth_date_string
FROM 
    String_Benchmark
ORDER BY
    email_length DESC,
    full_name ASC
LIMIT 100;
