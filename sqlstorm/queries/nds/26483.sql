
WITH string_benchmark AS (
    SELECT 
        c.c_first_name AS customer_first_name,
        c.c_last_name AS customer_last_name,
        ca.ca_city AS address_city,
        ca.ca_state AS address_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(ca.ca_city) AS upper_city,
        LOWER(ca.ca_state) AS lower_state,
        LENGTH(ca.ca_street_name) AS street_name_length,
        REPLACE(ca.ca_street_name, 'Street', 'St.') AS abbreviated_street_name,
        SUBSTRING(ca.ca_street_name, 1, 10) AS street_name_substring,
        POSITION('Main' IN ca.ca_street_name) AS position_of_main,
        TRIM(ca.ca_street_name) AS trimmed_street_name
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_month = 1 
        AND c.c_birth_day BETWEEN 1 AND 7
        AND (ca.ca_city LIKE 'San%' OR ca.ca_state = 'CA')
)
SELECT 
    customer_first_name,
    customer_last_name,
    address_city,
    address_state,
    full_name,
    upper_city,
    lower_state,
    street_name_length,
    abbreviated_street_name,
    street_name_substring,
    position_of_main,
    trimmed_street_name
FROM string_benchmark
ORDER BY customer_last_name, customer_first_name;
