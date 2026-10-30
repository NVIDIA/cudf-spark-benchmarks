
WITH StringBench AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS total_name_length,
        LOWER(CONCAT(c.c_first_name, c.c_last_name)) AS lower_full_name,
        UPPER(CONCAT(c.c_first_name, c.c_last_name)) AS upper_full_name,
        REPLACE(CONCAT(c.c_first_name, c.c_last_name), ' ', '-') AS replaced_full_name,
        SUBSTR(CONCAT(c.c_first_name, c.c_last_name), 1, 10) AS name_substr
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL
    ORDER BY 
        total_name_length DESC
)
SELECT 
    full_name, 
    total_name_length, 
    lower_full_name, 
    upper_full_name, 
    replaced_full_name, 
    name_substr
FROM 
    StringBench
LIMIT 100;
