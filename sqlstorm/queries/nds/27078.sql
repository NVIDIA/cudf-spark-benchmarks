
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
string_benchmark AS (
    SELECT 
        c.c_customer_sk,
        LENGTH(full_name) AS name_length,
        LENGTH(CONCAT(cd_gender, cd_marital_status, cd_education_status)) AS demographics_length,
        LENGTH(CONCAT(ca_city, ', ', ca_state, ', ', ca_country)) AS location_length,
        LENGTH(c_email_address) AS email_length
    FROM 
        customer_info c
)
SELECT 
    AVG(name_length) AS avg_name_length,
    AVG(demographics_length) AS avg_demographics_length,
    AVG(location_length) AS avg_location_length,
    AVG(email_length) AS avg_email_length,
    c_customer_sk
FROM 
    string_benchmark
WHERE 
    name_length > 0 AND 
    demographics_length > 0 AND 
    location_length > 0 AND 
    email_length > 0
GROUP BY 
    c_customer_sk
ORDER BY 
    avg_name_length DESC;
