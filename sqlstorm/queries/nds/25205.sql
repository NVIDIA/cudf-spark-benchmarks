
WITH StringLength AS (
    SELECT 
        c.c_customer_id,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        c.c_email_address,
        LENGTH(c.c_email_address) AS email_length,
        ca.ca_city,
        LENGTH(ca.ca_city) AS city_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregatedLengths AS (
    SELECT
        AVG(first_name_length) AS avg_first_name_length,
        AVG(last_name_length) AS avg_last_name_length,
        AVG(full_name_length) AS avg_full_name_length,
        AVG(email_length) AS avg_email_length,
        AVG(city_length) AS avg_city_length
    FROM 
        StringLength
),
StringStats AS (
    SELECT 
        LEAST(avg_first_name_length, avg_last_name_length, avg_full_name_length, avg_email_length, avg_city_length) AS min_length,
        GREATEST(avg_first_name_length, avg_last_name_length, avg_full_name_length, avg_email_length, avg_city_length) AS max_length,
        (avg_first_name_length + avg_last_name_length + avg_full_name_length + avg_email_length + avg_city_length) / 5 AS overall_avg_length
    FROM 
        AggregatedLengths
)
SELECT 
    *,
    CASE 
        WHEN overall_avg_length < 10 THEN 'Short'
        WHEN overall_avg_length BETWEEN 10 AND 20 THEN 'Medium'
        ELSE 'Long'
    END AS length_category
FROM 
    StringStats;
