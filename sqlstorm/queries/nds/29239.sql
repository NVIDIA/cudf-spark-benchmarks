
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_year DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    rc.full_name,
    rc.ca_city,
    rc.ca_state,
    rc.cd_gender,
    rc.cd_marital_status
FROM 
    RankedCustomers rc
WHERE 
    rc.rnk <= 10
ORDER BY 
    rc.ca_state, rc.full_name;
