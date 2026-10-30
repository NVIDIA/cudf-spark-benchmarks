
WITH processed_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        LENGTH(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS address_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    ORDER BY 
        ca.ca_city, name_length DESC
)
SELECT 
    full_name,
    full_address,
    ca_state,
    COUNT(*) OVER (PARTITION BY ca_state) AS count_by_state,
    AVG(cd_purchase_estimate) OVER (PARTITION BY ca_state) AS avg_purchase_estimate,
    MAX(name_length) OVER () AS max_name_length
FROM 
    processed_data
WHERE 
    name_length > 10
    AND address_length <= 100;
