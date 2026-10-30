
WITH AddressCTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip)) AS city_state_zip
    FROM 
        customer_address
),
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        da.full_address,
        da.city_state_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressCTE da ON c.c_current_addr_sk = da.ca_address_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    c.c_email_address,
    c.cd_gender,
    c.cd_marital_status,
    LENGTH(c.city_state_zip) AS address_length,
    REPLACE(UPPER(c.c_email_address), '.', '@') AS modified_email
FROM 
    CustomerCTE c
WHERE 
    c.cd_marital_status = 'M'
    AND c.cd_gender = 'F'
ORDER BY 
    address_length DESC, 
    c.c_last_name ASC;
