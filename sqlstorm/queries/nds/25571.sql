
WITH String_Processing AS (
    SELECT 
        c.c_first_name AS customer_first_name,
        c.c_last_name AS customer_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS lower_full_name,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS upper_full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        SUBSTR(CONCAT(c.c_first_name, ' ', c.c_last_name), 1, 5) AS name_substring,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '-') AS name_with_dashes,
        POSITION(' ' IN CONCAT(c.c_first_name, ' ', c.c_last_name)) AS space_position
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
)
SELECT 
    customer_first_name,
    customer_last_name,
    full_name,
    lower_full_name,
    upper_full_name,
    full_name_length,
    name_substring,
    name_with_dashes,
    space_position
FROM 
    String_Processing
ORDER BY 
    full_name_length DESC
LIMIT 100;
