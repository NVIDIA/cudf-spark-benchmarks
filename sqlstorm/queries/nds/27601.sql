
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ca.ca_city, 
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS customer_rank
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
    ca_state
FROM 
    RankedCustomers
WHERE 
    customer_rank <= 10
ORDER BY 
    cd_gender, full_name;
