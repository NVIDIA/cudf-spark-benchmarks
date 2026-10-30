
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IN ('M', 'F')
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(CASE WHEN ca.ca_state = 'CA' THEN 1 ELSE 0 END) AS ca_count,
        SUM(CASE WHEN ca.ca_state = 'NY' THEN 1 ELSE 0 END) AS ny_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
CustomerInfo AS (
    SELECT 
        rc.full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_count,
        ca.ny_count
    FROM 
        RankedCustomers rc
    JOIN 
        CustomerAddresses ca ON rc.c_customer_sk = ca.ca_address_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_count,
    ci.ny_count,
    (TRIM(UPPER(ci.full_name))) AS normalized_full_name,
    CONCAT('Customer in ', ci.ca_city, ', ', ci.ca_state) AS location_description
FROM 
    CustomerInfo ci
WHERE 
    ci.ca_count > 0
ORDER BY 
    ci.ca_count DESC, ci.ny_count ASC;
