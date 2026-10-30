
WITH StringProcessing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_email_address) AS email_upper,
        LOWER(c.c_birth_country) AS country_lower,
        CASE 
            WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
            ELSE 'Regular'
        END AS customer_type,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        REPLACE(c.c_email_address, '@', '[at]') AS email_obfuscated
    FROM customer c
    WHERE c.c_email_address LIKE '%@%'
),
AggregatedData AS (
    SELECT 
        full_name,
        email_upper,
        country_lower,
        customer_type,
        AVG(full_name_length) AS avg_name_length,
        COUNT(*) AS customer_count
    FROM StringProcessing
    GROUP BY full_name, email_upper, country_lower, customer_type
)
SELECT 
    customer_type,
    COUNT(*) AS total_customers,
    AVG(avg_name_length) AS average_full_name_length
FROM AggregatedData
GROUP BY customer_type
ORDER BY total_customers DESC;
