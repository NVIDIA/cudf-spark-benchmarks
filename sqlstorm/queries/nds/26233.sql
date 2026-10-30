
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS name_length,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS upper_full_name,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS lower_full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd.c_customer_id,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    cd.name_length,
    cd.upper_full_name,
    cd.lower_full_name
FROM 
    CustomerData cd
WHERE 
    cd.cd_gender = 'F'
    AND cd.ca_state IN ('CA', 'NY')
ORDER BY 
    cd.name_length DESC
LIMIT 100;
