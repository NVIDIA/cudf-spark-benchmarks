
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS rank
    FROM
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ca.ca_state IN ('CA', 'NY') AND
        cd.cd_gender = 'F'
)
SELECT 
    full_name,
    ca_city,
    ca_state
FROM 
    RankedCustomers
WHERE 
    rank <= 5
ORDER BY 
    ca_state, 
    ca_city, 
    full_name;
