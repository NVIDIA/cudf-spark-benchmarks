
WITH extracted_names AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_first_name IS NOT NULL AND c.c_last_name IS NOT NULL
),
name_statistics AS (
    SELECT 
        LENGTH(full_name) AS name_length,
        ca_city,
        ca_state,
        COUNT(*) AS name_count
    FROM 
        extracted_names
    GROUP BY 
        LENGTH(full_name), ca_city, ca_state
),
highest_counts AS (
    SELECT 
        ca_city,
        ca_state,
        MAX(name_count) AS max_count
    FROM 
        name_statistics
    GROUP BY 
        ca_city, ca_state
),
final_result AS (
    SELECT 
        ns.ca_city,
        ns.ca_state,
        ns.name_length,
        ns.name_count,
        hc.max_count
    FROM 
        name_statistics ns
    JOIN 
        highest_counts hc ON ns.ca_city = hc.ca_city AND ns.ca_state = hc.ca_state
    WHERE 
        ns.name_count = hc.max_count
)
SELECT 
    ca_city,
    ca_state,
    MIN(name_length) AS min_name_length,
    AVG(name_length) AS avg_name_length,
    MAX(name_length) AS max_name_length,
    SUM(name_count) AS total_names
FROM 
    final_result
GROUP BY 
    ca_city, ca_state
ORDER BY 
    ca_state, ca_city;
