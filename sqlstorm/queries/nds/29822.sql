
WITH processed_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS birth_year_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_education_status IN ('PhD', 'Masters', 'Bachelors')
)
SELECT 
    full_name,
    c_email_address,
    full_address,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    birth_year_rank
FROM 
    processed_customers
WHERE 
    birth_year_rank <= 5
ORDER BY 
    cd_gender, 
    birth_year_rank;
