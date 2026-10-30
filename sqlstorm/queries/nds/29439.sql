
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
TopAddresses AS (
    SELECT 
        ca_state,
        address_count,
        RANK() OVER (ORDER BY address_count DESC) AS state_rank
    FROM 
        AddressCounts
    WHERE 
        address_count > 100
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    ta.ca_state,
    ta.address_count
FROM 
    RankedCustomers rc
JOIN 
    TopAddresses ta ON (rc.rn <= 3)
ORDER BY 
    ta.address_count DESC, 
    rc.full_name;
