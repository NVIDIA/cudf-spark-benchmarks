
WITH string_benchmark AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        SUBSTRING(c_email_address, POSITION('@' IN c_email_address) + 1) AS domain,
        LENGTH(c_email_address) AS email_length,
        LOWER(c_first_name) AS lower_first_name,
        UPPER(c_last_name) AS upper_last_name
    FROM 
        customer 
    WHERE 
        c_birth_year > 1980
),
aggregated_results AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(email_length) AS avg_email_length,
        COUNT(DISTINCT domain) AS unique_domains
    FROM 
        string_benchmark
)
SELECT 
    total_customers,
    avg_email_length,
    unique_domains,
    CONCAT('Average email length: ', ROUND(avg_email_length, 2)) AS email_length_info,
    CONCAT('Total customers from 1980 onward: ', total_customers) AS customer_info,
    CONCAT('Unique email domains: ', unique_domains) AS domain_info
FROM 
    aggregated_results;
