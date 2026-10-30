
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name, c.c_first_name) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    CONCAT(cfirst.c_first_name, ' ', cfirst.c_last_name) AS full_name,
    cfirst.cd_gender,
    cfirst.cd_marital_status,
    cfirst.ca_city,
    cfirst.ca_state
FROM 
    ranked_customers cfirst
WHERE 
    cfirst.rank <= 5
ORDER BY 
    cfirst.cd_gender, 
    cfirst.cd_marital_status, 
    full_name;
