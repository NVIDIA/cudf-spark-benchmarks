
WITH String_Benchmark AS (
    SELECT 
        c.c_customer_id AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(UPPER(c.c_first_name), ' ', LOWER(c.c_last_name)) AS formatted_name,
        LENGTH(c.c_email_address) AS email_length,
        LOWER(c.c_email_address) AS lowercased_email,
        UPPER(c.c_email_address) AS uppercased_email,
        REPLACE(c.c_email_address, '@', '[at]') AS email_with_placeholder,
        SUBSTRING(c.c_email_address, 1, 5) AS email_prefix
    FROM 
        customer c
    WHERE 
        c.c_email_address IS NOT NULL 
        AND LENGTH(c.c_email_address) > 5
),
Aggregate_Benchmarks AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(email_length) AS avg_email_length,
        MAX(email_length) AS max_email_length,
        MIN(email_length) AS min_email_length,
        COUNT(DISTINCT lowercased_email) AS unique_lowercase_emails
    FROM 
        String_Benchmark
)
SELECT 
    ab.total_customers,
    ab.avg_email_length,
    ab.max_email_length,
    ab.min_email_length,
    ab.unique_lowercase_emails,
    MAX(sb.formatted_name) AS longest_full_name,
    COUNT(CASE WHEN sb.email_length BETWEEN 6 AND 20 THEN 1 END) AS emails_between_6_and_20_chars,
    COUNT(CASE WHEN sb.email_length > 20 THEN 1 END) AS long_emails
FROM 
    Aggregate_Benchmarks ab
JOIN 
    String_Benchmark sb ON TRUE
GROUP BY 
    ab.total_customers, 
    ab.avg_email_length, 
    ab.max_email_length, 
    ab.min_email_length, 
    ab.unique_lowercase_emails;
