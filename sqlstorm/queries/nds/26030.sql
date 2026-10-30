
WITH StringBenchmark AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length,
        LOWER(c.c_email_address) AS lower_email,
        UPPER(c.c_email_address) AS upper_email,
        REPLACE(c.c_email_address, '@', '[at]') AS modified_email,
        REGEXP_REPLACE(c.c_email_address, '[^a-zA-Z0-9@._-]', '') AS sanitized_email
    FROM 
        customer c
    WHERE 
        c.c_email_address IS NOT NULL
),
BenchmarkResults AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(email_length) AS avg_email_length,
        COUNT(DISTINCT full_name) AS unique_full_names,
        COUNT(DISTINCT lower_email) AS unique_lower_emails,
        COUNT(DISTINCT upper_email) AS unique_upper_emails,
        COUNT(DISTINCT modified_email) AS unique_modified_emails,
        COUNT(DISTINCT sanitized_email) AS unique_sanitized_emails
    FROM 
        StringBenchmark
)
SELECT 
    total_customers,
    avg_email_length,
    unique_full_names,
    unique_lower_emails,
    unique_upper_emails,
    unique_modified_emails,
    unique_sanitized_emails
FROM 
    BenchmarkResults;
