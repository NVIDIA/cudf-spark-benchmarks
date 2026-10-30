
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_month BETWEEN 1 AND 12
),
RecentAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_street_name,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_address_sk DESC) AS address_rn
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('NY', 'CA')
),
CustomerAddressDetails AS (
    SELECT 
        rc.full_name,
        ra.ca_city,
        ra.ca_state,
        ra.ca_country,
        ra.ca_street_name,
        ra.ca_zip
    FROM 
        RankedCustomers rc
    JOIN 
        RecentAddresses ra ON ra.address_rn = 1
    WHERE 
        rc.rn <= 10
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    ca_street_name,
    ca_zip
FROM 
    CustomerAddressDetails
ORDER BY 
    ca_state, ca_city, full_name;
