
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS total_customers,
        MAX(rn) AS max_rank
    FROM 
        RankedCustomers rc
    JOIN 
        customer_demographics cd ON rc.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    rc.full_name,
    cs.total_customers,
    cs.max_rank
FROM 
    RankedCustomers rc
JOIN 
    CustomerStats cs ON rc.cd_gender = cs.cd_gender
WHERE 
    rc.rn <= 5
ORDER BY 
    rc.cd_gender, rc.rn;
