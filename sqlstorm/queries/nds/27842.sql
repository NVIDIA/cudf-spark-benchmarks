
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    upper(full_name) AS upper_name,
    lower(full_name) AS lower_name,
    LENGTH(full_name) AS name_length,
    SUBSTR(full_name, 1, 5) AS name_prefix,
    REGEXP_REPLACE(full_name, '[A-Za-z]', '*') AS masked_name,
    ca_city || ', ' || ca_state AS full_location,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate
FROM 
    customer_info
WHERE 
    city_rank <= 10
ORDER BY 
    ca_state, 
    cd_purchase_estimate DESC;
