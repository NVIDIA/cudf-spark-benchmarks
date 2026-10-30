
WITH StringMetrics AS (
    SELECT 
        c.c_customer_id,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        LENGTH(c.c_email_address) AS email_length,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_last_name) AS last_name_uppercase,
        LOWER(c.c_email_address) AS email_lowercase,
        TRIM(c.c_first_name) AS first_name_trimmed,
        REGEXP_REPLACE(c.c_email_address, '^[^@]+@', '') AS email_domain,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_last_name) AS rnk
    FROM 
        customer c
    WHERE 
        c.c_first_name IS NOT NULL 
        AND c.c_last_name IS NOT NULL 
        AND c.c_email_address IS NOT NULL
),
FilteredMetrics AS (
    SELECT 
        *,
        CONCAT(first_name_length, '-', last_name_length, '-', email_length) AS length_summary
    FROM 
        StringMetrics
    WHERE 
        rnk <= 1000
)
SELECT 
    full_name,
    last_name_uppercase,
    email_lowercase,
    email_domain,
    length_summary
FROM 
    FilteredMetrics
ORDER BY 
    first_name_length DESC, 
    last_name_length DESC,
    email_length DESC;
