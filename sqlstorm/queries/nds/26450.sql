
WITH AddressStringProcessing AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS city_state_zip,
        INITCAP(ca.ca_country) AS formatted_country,
        LENGTH(ca.ca_street_name) AS street_name_length,
        CASE 
            WHEN LENGTH(ca.ca_street_name) > 30 THEN 'Long Street Name'
            ELSE 'Short Street Name'
        END AS street_name_length_category
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
StringStatistics AS (
    SELECT 
        AVG(street_name_length) AS avg_street_name_length,
        COUNT(DISTINCT full_name) AS unique_customer_names,
        COUNT(*) AS total_entries
    FROM 
        AddressStringProcessing
)
SELECT 
    avg_street_name_length,
    unique_customer_names,
    total_entries,
    CONCAT(CAST(avg_street_name_length AS STRING), ' characters') AS avg_length_string,
    CONCAT(CAST(total_entries AS STRING), ' total entries') AS total_entries_string
FROM 
    StringStatistics;
