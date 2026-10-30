
WITH processed_strings AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(c.c_email_address) AS email_lower,
        UPPER(SUBSTRING(c.c_birth_country FROM 1 FOR 3)) AS country_prefix,
        TRIM(REPLACE(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city), '  ', ' ')) AS address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(LENGTH(full_name)) AS avg_full_name_length,
    AVG(LENGTH(email_lower)) AS avg_email_length,
    COUNT(DISTINCT country_prefix) AS unique_country_prefix_count,
    COUNT(DISTINCT address) AS unique_address_count
FROM 
    processed_strings
WHERE 
    email_lower LIKE '%@example.com'
    AND LENGTH(full_name) > 10;
