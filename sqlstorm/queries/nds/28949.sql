
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        cd_gender,
        cd_marital_status,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY c_birth_year DESC) AS age_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    r.full_name,
    r.full_address,
    r.cd_gender,
    r.cd_marital_status,
    r.age_rank,
    COUNT(*) OVER (PARTITION BY r.age_rank) AS count_same_age_rank
FROM 
    RankedCustomers r
WHERE 
    r.cd_marital_status = 'M'
ORDER BY 
    r.cd_gender, r.age_rank, r.full_name;
