
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_email_address, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_spending
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip, 
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerRankedAddresses AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.c_email_address, 
        rc.cd_gender, 
        rc.cd_marital_status, 
        ad.full_address, 
        ad.ca_city, 
        ad.ca_state, 
        ad.ca_zip, 
        ad.ca_country
    FROM 
        RankedCustomers rc
    JOIN 
        AddressDetails ad ON rc.c_customer_sk = ad.ca_address_sk
    WHERE 
        rc.rank_by_spending <= 10
)
SELECT 
    CONCAT(cra.c_first_name, ' ', cra.c_last_name) AS customer_name, 
    cra.c_email_address, 
    cra.full_address, 
    cra.ca_city, 
    cra.ca_state, 
    cra.ca_zip, 
    cra.ca_country, 
    cra.cd_gender, 
    cra.cd_marital_status
FROM 
    CustomerRankedAddresses cra
ORDER BY 
    cra.cd_gender, 
    cra.cd_marital_status, 
    cra.c_customer_sk;
