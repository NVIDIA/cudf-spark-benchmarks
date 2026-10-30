
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               ' ', COALESCE(ca_suite_number, ''), ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
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
FilteredCustomers AS (
    SELECT 
        ci.c_customer_sk, 
        ci.full_name, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ac.address_count
    FROM 
        CustomerInfo ci
    JOIN 
        customer_address ca ON ca.ca_address_sk = ci.c_customer_sk 
    JOIN 
        AddressCounts ac ON ac.ca_state = ca.ca_state
    WHERE 
        ci.cd_gender = 'F'
)
SELECT 
    fc.full_name,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.address_count,
    a.full_address
FROM 
    FilteredCustomers fc
JOIN 
    AddressInfo a ON a.ca_address_sk = fc.c_customer_sk
ORDER BY 
    fc.address_count DESC, 
    fc.full_name;
