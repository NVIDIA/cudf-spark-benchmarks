
WITH CustomerData AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS birth_rank,
        COUNT(*) OVER (PARTITION BY cd.cd_gender) AS gender_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'S' AND cd.cd_purchase_estimate > 1000
),
RankedCustomers AS (
    SELECT 
        full_name,
        full_address,
        cd_gender,
        birth_rank,
        gender_count,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY birth_rank) AS row_num
    FROM 
        CustomerData
)
SELECT 
    full_name,
    full_address,
    cd_gender,
    birth_rank,
    gender_count
FROM 
    RankedCustomers
WHERE 
    row_num <= 10
ORDER BY 
    cd_gender, birth_rank DESC;
