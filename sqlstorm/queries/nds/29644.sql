
WITH String_Manipulation AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_email_address) AS email_upper,
        TRIM(c.c_birth_country) AS birth_country_trimmed,
        LEFT(c.c_first_name, 1) || '.' AS first_initial,
        REPLACE(c.c_first_name, 'a', '@') AS first_name_replaced
    FROM 
        customer c
    WHERE 
        c.c_birth_country IS NOT NULL
),
Aggregated_Results AS (
    SELECT 
        COUNT(*) AS total_customers,
        COUNT(DISTINCT full_name) AS unique_full_names,
        COUNT(DISTINCT email_upper) AS unique_email_upper,
        COUNT(DISTINCT birth_country_trimmed) AS unique_birth_countries,
        COUNT(DISTINCT first_initial) AS unique_first_initials,
        COUNT(DISTINCT first_name_replaced) AS unique_first_name_replaced
    FROM 
        String_Manipulation
)
SELECT 
    total_customers,
    unique_full_names,
    unique_email_upper,
    unique_birth_countries,
    unique_first_initials,
    unique_first_name_replaced,
    ROUND(total_customers * 1.0 / NULLIF(unique_full_names, 0), 2) AS avg_full_names_per_customer,
    ROUND(total_customers * 1.0 / NULLIF(unique_email_upper, 0), 2) AS avg_emails_per_customer,
    ROUND(total_customers * 1.0 / NULLIF(unique_birth_countries, 0), 2) AS avg_birth_countries_per_customer,
    ROUND(total_customers * 1.0 / NULLIF(unique_first_initials, 0), 2) AS avg_initials_per_customer,
    ROUND(total_customers * 1.0 / NULLIF(unique_first_name_replaced, 0), 2) AS avg_replaced_names_per_customer
FROM 
    Aggregated_Results;
