
WITH detailed_customer AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 300 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 300 AND 700 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_estimate_band
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_city IS NOT NULL
        AND ca.ca_state IN ('CA', 'TX', 'NY')
),
string_benchmark AS (
    SELECT 
        full_name,
        LENGTH(full_name) AS name_length,
        UPPER(full_name) AS name_uppercase,
        LOWER(full_name) AS name_lowercase,
        REPLACE(full_name, ' ', '-') AS name_with_dashes,
        SUBSTRING(full_name FROM 1 FOR 5) AS name_first_five_chars
    FROM 
        detailed_customer
)
SELECT 
    AVG(name_length) AS average_name_length,
    COUNT(DISTINCT name_uppercase) AS unique_uppercase_names,
    COUNT(name_with_dashes) AS total_dashed_names,
    COUNT(name_first_five_chars) AS total_first_five_chars_extracted
FROM 
    string_benchmark;
