
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        SUBSTRING(c.c_email_address FROM 1 FOR 5) AS email_prefix,
        UPPER(ca.ca_street_name) AS upper_street_name,
        LOWER(cd.cd_credit_rating) AS lower_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), aggregated_data AS (
    SELECT 
        ci.*, 
        COUNT(*) OVER (PARTITION BY ci.ca_city, ci.ca_state) AS count_per_city_state
    FROM 
        customer_info ci
)
SELECT 
    full_name,
    ci.ca_city,
    ci.ca_state,
    COUNT(DISTINCT ci.c_customer_id) AS unique_customers,
    MAX(upper_street_name) AS max_street_name,
    MIN(lower_credit_rating) AS min_credit_rating,
    AVG(count_per_city_state) AS avg_customers_per_city_state
FROM 
    aggregated_data ci
GROUP BY 
    full_name, ci.ca_city, ci.ca_state
HAVING 
    COUNT(DISTINCT ci.c_customer_id) > 10
ORDER BY 
    ci.ca_state, ci.ca_city, unique_customers DESC;
