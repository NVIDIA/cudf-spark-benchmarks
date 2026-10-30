
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FormattedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
                  CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT('Suite', ca.ca_suite_number) END, 
                  ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.cd_gender, 
        rc.cd_marital_status, 
        rc.cd_education_status, 
        fa.full_address
    FROM 
        RankedCustomers rc
    JOIN 
        FormattedAddresses fa ON rc.c_customer_sk = fa.ca_address_sk
    WHERE 
        rc.rn = 1
)
SELECT 
    cd.c_first_name || ' ' || cd.c_last_name AS customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.full_address
FROM 
    CustomerDetails cd
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    cd.c_last_name, cd.c_first_name;
