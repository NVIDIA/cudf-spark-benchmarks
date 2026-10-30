
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M'
)

SELECT 
    full_name,
    cd_gender,
    full_address,
    COUNT(*) OVER (PARTITION BY cd_gender) AS total_customers,
    CONCAT(LEFT(full_address, 40), '...') AS address_preview
FROM 
    RankedCustomers
WHERE 
    rn <= 10
ORDER BY 
    cd_gender, full_name;
