
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        ra.c_customer_sk,
        CONCAT(ra.c_first_name, ' ', ra.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        RankedCustomers ra
    JOIN 
        customer_address ca ON ra.c_customer_sk = ca.ca_address_sk
    WHERE 
        ra.rnk <= 10
),
CustomerDetails AS (
    SELECT 
        ca.full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        CustomerAddresses ca
)
SELECT 
    full_name,
    full_address,
    LENGTH(full_address) AS address_length,
    UPPER(full_address) AS address_uppercase,
    REPLACE(full_address, ' ', '-') AS address_hyphenated
FROM 
    CustomerDetails
ORDER BY 
    address_length DESC;
