
WITH String_Benchmark AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(c.c_email_address, '@', '#') AS modified_email,
        UPPER(c.c_birth_country) AS birth_country_upper,
        LOWER(c.c_login) AS login_lower,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        LENGTH(c.c_email_address) AS email_length,
        LENGTH(c.c_birth_country) AS country_length
    FROM 
        customer c
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
Aggregate_Benchmarks AS (
    SELECT 
        AVG(first_name_length) AS avg_first_name_length,
        AVG(last_name_length) AS avg_last_name_length,
        AVG(email_length) AS avg_email_length,
        AVG(country_length) AS avg_country_length
    FROM 
        String_Benchmark
)
SELECT 
    sb.full_name, 
    sb.modified_email, 
    sb.birth_country_upper, 
    sb.login_lower, 
    ab.avg_first_name_length, 
    ab.avg_last_name_length, 
    ab.avg_email_length, 
    ab.avg_country_length
FROM 
    String_Benchmark sb, 
    Aggregate_Benchmarks ab
ORDER BY 
    sb.full_name;
