
WITH StringBenchmark AS (
    SELECT 
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        SUBSTRING(c.c_email_address, 1, 5) AS email_prefix,
        REPLACE(c.c_email_address, '@', '[at]') AS obfuscated_email,
        UPPER(c.c_last_name) AS last_name_upper,
        LOWER(c.c_first_name) AS first_name_lower,
        CHAR_LENGTH(c.c_email_address) AS email_length,
        REGEXP_REPLACE(c.c_email_address, '[^a-zA-Z0-9]', '') AS email_alpha_numeric,
        c.c_birth_month AS birth_month,
        CASE 
            WHEN c.c_birth_month IN (1, 2, 3) THEN 'Q1'
            WHEN c.c_birth_month IN (4, 5, 6) THEN 'Q2'
            WHEN c.c_birth_month IN (7, 8, 9) THEN 'Q3'
            WHEN c.c_birth_month IN (10, 11, 12) THEN 'Q4'
        END AS birth_quarter
    FROM 
        customer c
    WHERE 
        c.c_first_name IS NOT NULL 
        AND c.c_last_name IS NOT NULL
)
SELECT 
    COUNT(*) AS total_records,
    AVG(full_name_length) AS average_full_name_length,
    COUNT(DISTINCT email_prefix) AS unique_email_prefixes,
    AVG(email_length) AS average_email_length,
    COUNT(DISTINCT birth_quarter) AS distinct_birth_quarters,
    MAX(last_name_upper) AS max_last_name_upper,
    MIN(first_name_lower) AS min_first_name_lower
FROM 
    StringBenchmark
GROUP BY 
    full_name_length, email_length, last_name_upper, first_name_lower;
