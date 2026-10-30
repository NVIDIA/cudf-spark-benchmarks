
WITH string_benchmark AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length,
        LOWER(TRIM(ca.ca_street_name)) AS normalized_street_name,
        UPPER(ca.ca_city) AS upper_city
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
aggregated_benchmarks AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(email_length) AS avg_email_length,
        COUNT(DISTINCT normalized_street_name) AS unique_street_names,
        COUNT(DISTINCT upper_city) AS unique_upper_cities
    FROM 
        string_benchmark
)
SELECT 
    total_customers,
    avg_email_length,
    unique_street_names,
    unique_upper_cities,
    CONCAT('Total: ', total_customers, ', Avg Email Length: ', avg_email_length, ', Unique Street Names: ', unique_street_names, ', Unique Upper Cities: ', unique_upper_cities) AS benchmark_summary
FROM 
    aggregated_benchmarks;
