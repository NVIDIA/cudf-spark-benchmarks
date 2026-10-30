
WITH String_Benchmark AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS combined_length,
        UPPER(c.c_first_name) AS upper_first_name,
        LOWER(c.c_last_name) AS lower_last_name,
        REGEXP_REPLACE(c.c_email_address, '@.*$', '') AS email_prefix,
        CHAR_LENGTH(c.c_email_address) AS email_length,
        SUBSTRING(c.c_email_address, 1, 10) AS email_substring,
        CASE 
            WHEN LENGTH(c.c_first_name) > 5 THEN 'Long'
            ELSE 'Short'
        END AS first_name_length_category,
        CASE 
            WHEN c.c_birth_year BETWEEN 1980 AND 1990 THEN 'Millennial'
            ELSE 'Other'
        END AS birth_year_category
    FROM 
        customer AS c
    WHERE 
        c.c_preferred_cust_flag = 'Y'
)

SELECT 
    COUNT(*) AS total_customers,
    AVG(combined_length) AS avg_combined_length,
    MAX(email_length) AS max_email_length,
    MIN(email_length) AS min_email_length,
    COUNT(DISTINCT first_name_length_category) AS unique_first_name_length_categories,
    COUNT(DISTINCT birth_year_category) AS unique_birth_year_categories
FROM 
    String_Benchmark
WHERE 
    full_name IS NOT NULL
GROUP BY 
    first_name_length_category, 
    birth_year_category,
    combined_length,
    email_length
ORDER BY 
    total_customers DESC;
