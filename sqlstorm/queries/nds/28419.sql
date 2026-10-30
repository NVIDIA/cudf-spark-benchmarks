
WITH string_benchmark AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(LOWER(c.c_email_address), '@', ' [at] ') AS modified_email,
        LENGTH(c.c_email_address) AS email_length,
        COUNT(DISTINCT ca.ca_address_id) AS address_count,
        SUBSTRING(c.c_first_name, 1, 3) AS name_prefix,
        LEFT(c.c_last_name, 5) AS last_name_short,
        RTRIM(UPPER(ca.ca_city)) AS city_upper,
        REGEXP_REPLACE(ca.ca_street_name, ' St| Ave', '') AS street_cleaned
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address, ca.ca_address_id, ca.ca_city, ca.ca_street_name
)
SELECT 
    full_name,
    modified_email,
    email_length,
    address_count,
    name_prefix,
    last_name_short,
    city_upper,
    street_cleaned
FROM 
    string_benchmark
WHERE 
    email_length > 20
ORDER BY 
    full_name DESC
LIMIT 100;
