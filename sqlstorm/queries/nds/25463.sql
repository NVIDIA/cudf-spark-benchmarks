
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        da.ca_city,
        da.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY da.ca_city, da.ca_state ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_address da ON c.c_current_addr_sk = da.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        da.ca_city IS NOT NULL AND
        da.ca_state IS NOT NULL
)
SELECT 
    full_name, 
    ca_city, 
    ca_state, 
    cd_gender, 
    cd_marital_status
FROM 
    ranked_customers
WHERE 
    rank <= 10
ORDER BY 
    ca_city, 
    ca_state, 
    FULL_NAME;
