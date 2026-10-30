
WITH String_Processing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        TRIM(UPPER(CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END)) AS gender,
        SUBSTRING(c.c_email_address, 1, 10) AS email_prefix,
        REPLACE(ca.ca_city, 'City', 'Town') AS modified_city,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        LENGTH(c.c_email_address) AS email_length
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE LENGTH(c.c_email_address) > 5
),
Aggregated_Data AS (
    SELECT 
        gender,
        COUNT(*) AS customer_count,
        AVG(first_name_length) AS avg_first_name_length,
        AVG(last_name_length) AS avg_last_name_length,
        AVG(email_length) AS avg_email_length
    FROM String_Processing
    GROUP BY gender
)
SELECT 
    gender,
    customer_count,
    avg_first_name_length,
    avg_last_name_length,
    avg_email_length,
    CONCAT(ROUND((avg_first_name_length + avg_last_name_length + avg_email_length) / 3, 2), ' - Avg Char Length') AS average_character_length
FROM Aggregated_Data
ORDER BY customer_count DESC;
