
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
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
FilteredCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
),
AddressStats AS (
    SELECT 
        ca.ca_city,
        COUNT(c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT ca.ca_zip) AS unique_zip_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    fc.full_name,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.cd_education_status,
    a.ca_city,
    a.customer_count,
    a.unique_zip_count
FROM 
    FilteredCustomers fc
JOIN 
    AddressStats a ON a.customer_count > 0
ORDER BY 
    a.customer_count DESC, 
    fc.full_name;
