
WITH processed_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        LENGTH(ca.ca_street_name) AS street_name_length,
        UPPER(ca.ca_street_name) AS uppercase_street_name,
        COUNT(DISTINCT c.c_email_address) AS email_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_month = 10 AND c.c_birth_day BETWEEN 1 AND 31
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_street_name
),
aggregated_data AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_customers,
        AVG(street_name_length) AS avg_street_name_length,
        MAX(email_count) AS max_email_count
    FROM 
        processed_data
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    a.total_customers,
    a.avg_street_name_length,
    a.max_email_count,
    CASE 
        WHEN a.total_customers > 100 THEN 'High'
        WHEN a.total_customers BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment
FROM 
    aggregated_data a
ORDER BY 
    a.total_customers DESC;
