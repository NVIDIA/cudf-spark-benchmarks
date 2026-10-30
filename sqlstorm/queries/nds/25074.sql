
WITH detailed_customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
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
string_benchmarks AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        LENGTH(full_name) AS name_length,
        CHAR_LENGTH(ca_city) AS city_length,
        CHAR_LENGTH(ca_state) AS state_length,
        REPLACE(UPPER(full_name), ' ', '') AS name_no_spaces,
        REPLACE(REPLACE(UPPER(ca_city), ' ', ''), '-', '') AS city_no_spaces,
        REPLACE(REPLACE(UPPER(ca_state), ' ', ''), '-', '') AS state_no_spaces
    FROM 
        detailed_customer_info
)
SELECT 
    AVG(name_length) AS avg_name_length,
    AVG(city_length) AS avg_city_length,
    AVG(state_length) AS avg_state_length,
    COUNT(DISTINCT name_no_spaces) AS unique_names,
    COUNT(DISTINCT city_no_spaces) AS unique_cities,
    COUNT(DISTINCT state_no_spaces) AS unique_states
FROM 
    string_benchmarks;
