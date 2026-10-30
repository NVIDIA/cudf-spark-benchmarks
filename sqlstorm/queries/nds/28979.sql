
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressCityCount AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
FilteredCustomerData AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        ac.address_count
    FROM 
        RankedCustomers rc
    JOIN 
        AddressCityCount ac ON rc.rank <= 10
)
SELECT 
    fcd.full_name,
    fcd.cd_gender,
    fcd.cd_marital_status,
    fcd.cd_education_status,
    fcd.address_count
FROM 
    FilteredCustomerData fcd
WHERE 
    fcd.address_count > 5
ORDER BY 
    fcd.cd_gender, fcd.cd_marital_status;
