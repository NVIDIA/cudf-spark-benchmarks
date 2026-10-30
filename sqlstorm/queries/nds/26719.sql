
WITH enriched_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city AS city,
        ca.ca_state AS state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_upper,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_lower,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '_') AS full_name_replaced
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    city,
    state,
    COUNT(*) AS customer_count,
    AVG(name_length) AS avg_name_length,
    MAX(name_length) AS max_name_length,
    MIN(name_length) AS min_name_length,
    COUNT(DISTINCT full_name_upper) AS distinct_uppercase_names,
    COUNT(DISTINCT full_name_lower) AS distinct_lowercase_names,
    COUNT(DISTINCT full_name_replaced) AS distinct_replaced_names
FROM 
    enriched_data
GROUP BY 
    city, 
    state
ORDER BY 
    city, 
    state;
