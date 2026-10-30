
WITH CustomerInformation AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StringBenchmark AS (
    SELECT
        full_name,
        ca_state,
        LENGTH(full_name) AS name_length,
        UPPER(full_name) AS name_uppercase,
        LOWER(full_name) AS name_lowercase,
        REPLACE(full_name, ' ', '_') AS name_replaced,
        CONCAT(full_name, ' - ', ca_state) AS name_with_state,
        REVERSE(full_name) AS name_reversed,
        REGEXP_REPLACE(full_name, '[^A-Za-z0-9]', '') AS name_alpha_numeric
    FROM 
        CustomerInformation
)
SELECT 
    ca_state,
    COUNT(*) AS total_customers,
    AVG(name_length) AS avg_name_length,
    COUNT(DISTINCT name_uppercase) AS unique_uppercase_names,
    COUNT(DISTINCT name_replaced) AS unique_replaced_names,
    COUNT(DISTINCT name_with_state) AS unique_names_with_state,
    COUNT(DISTINCT name_reversed) AS unique_reversed_names,
    COUNT(DISTINCT name_alpha_numeric) AS unique_alpha_numeric_names
FROM 
    StringBenchmark
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC;
