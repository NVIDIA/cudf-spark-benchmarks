
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), ', ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip)) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ap.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ap ON c.c_current_addr_sk = ap.ca_address_sk
),
AddressAnalysis AS (
    SELECT 
        full_address,
        LENGTH(full_address) AS address_length,
        CASE 
            WHEN lower(full_address) LIKE '%street%' THEN 'Contains Street'
            WHEN lower(full_address) LIKE '%avenue%' THEN 'Contains Avenue'
            ELSE 'Other'
        END AS address_type
    FROM 
        AddressParts
)
SELECT 
    DISTINCT cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    aa.address_length,
    aa.address_type
FROM 
    CustomerDetails cd
JOIN 
    AddressAnalysis aa ON cd.full_address = aa.full_address
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    aa.address_length DESC
LIMIT 50;
