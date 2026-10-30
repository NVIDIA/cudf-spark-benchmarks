
WITH StringBenchmark AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        TRIM(UPPER(c.c_email_address)) AS normalized_email,
        REPLACE(ca.ca_street_name, 'St', 'Street') AS standardized_street_name,
        LENGTH(ca.ca_city) AS city_length,
        SUBSTRING(ca.ca_zip, 1, 5) AS zip_prefix,
        LEFT(ca.ca_country, 3) AS country_abbreviation
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_first_name IS NOT NULL AND c.c_last_name IS NOT NULL
),
AggregatedResults AS (
    SELECT 
        COUNT(*) AS total_customers,
        COUNT(DISTINCT full_name) AS unique_full_names,
        COUNT(DISTINCT normalized_email) AS unique_emails,
        AVG(city_length) AS avg_city_length,
        COUNT(DISTINCT zip_prefix) AS unique_zip_prefixes,
        COUNT(DISTINCT country_abbreviation) AS unique_country_abbreviations
    FROM 
        StringBenchmark
)
SELECT 
    total_customers,
    unique_full_names,
    unique_emails,
    avg_city_length,
    unique_zip_prefixes,
    unique_country_abbreviations
FROM 
    AggregatedResults;
