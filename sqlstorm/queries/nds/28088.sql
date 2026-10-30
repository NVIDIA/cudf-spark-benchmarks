
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(COALESCE(c.c_salutation, ''), ' ', c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        ca.ca_city, 
        ca.ca_state,
        ca.ca_zip, 
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_zip,
    ca_country
FROM 
    CustomerDetails
WHERE 
    city_rank <= 5 
ORDER BY 
    ca_city, full_name;
