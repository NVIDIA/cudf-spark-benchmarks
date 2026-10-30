
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                         THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CONCAT('Address: ', ad.full_address, ', ', ad.ca_city, ', ', ad.ca_state, ' ', ad.ca_zip, ', ', ad.ca_country) AS complete_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT 
    cd.full_name,
    cd.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.complete_address
FROM 
    CustomerDetails cd
WHERE 
    cd.cd_purchase_estimate > 1000 AND 
    cd.cd_gender = 'F' AND 
    cd.cd_marital_status = 'M'
ORDER BY 
    cd.cd_purchase_estimate DESC
LIMIT 50;
