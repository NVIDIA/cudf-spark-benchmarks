
WITH string_benchmarks AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length,
        c.c_email_address,
        REPLACE(c.c_email_address, '@', '[at]') AS obfuscated_email,
        REGEXP_REPLACE(c.c_email_address, '([a-zA-Z0-9._%+-]+)@.*', '$1@[obfuscated]') AS regex_obfuscated_email,
        CONCAT(LEFT(c.c_first_name, 1), LOWER(c.c_last_name)) AS username,
        CONCAT('Customer from ', ca.ca_city, ', ', ca.ca_state) AS location_info
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
aggregated_metrics AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(email_length) AS avg_email_length,
        MAX(LENGTH(full_name)) AS max_full_name_length,
        MIN(LENGTH(full_name)) AS min_full_name_length
    FROM 
        string_benchmarks
)
SELECT 
    s.full_name,
    s.email_length,
    s.obfuscated_email,
    s.regex_obfuscated_email,
    s.username,
    s.location_info,
    a.total_customers,
    a.avg_email_length,
    a.max_full_name_length,
    a.min_full_name_length
FROM 
    string_benchmarks s, 
    aggregated_metrics a
GROUP BY 
    s.c_customer_id, s.full_name, s.email_length, s.obfuscated_email, s.regex_obfuscated_email, s.username, s.location_info,
    a.total_customers, a.avg_email_length, a.max_full_name_length, a.min_full_name_length
ORDER BY 
    s.c_customer_id
LIMIT 50;
