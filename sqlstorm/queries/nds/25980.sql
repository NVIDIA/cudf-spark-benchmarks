
WITH StringMetrics AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_local_part,
        LENGTH(SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1)) AS email_local_length,
        ca.ca_city AS city,
        ca.ca_state AS state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
),
AggregatedMetrics AS (
    SELECT 
        city,
        state,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(full_name_length) AS avg_full_name_length,
        AVG(email_local_length) AS avg_email_local_length
    FROM StringMetrics
    GROUP BY city, state
)
SELECT 
    city,
    state,
    customer_count,
    avg_full_name_length,
    avg_email_local_length,
    CASE 
        WHEN customer_count > 100 THEN 'High Customer Volume'
        WHEN customer_count BETWEEN 50 AND 100 THEN 'Medium Customer Volume'
        ELSE 'Low Customer Volume'
    END AS customer_volume_category
FROM AggregatedMetrics
ORDER BY customer_count DESC, state ASC;
