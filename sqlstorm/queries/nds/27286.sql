
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
        ca_city, 
        ca_state, 
        ca_zip 
    FROM 
        customer_address 
    WHERE 
        ca_city LIKE '%Ville%' 
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        LOWER(cd_education_status) AS education 
    FROM 
        customer_demographics 
    WHERE 
        cd_gender IN ('F', 'M') 
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        c.c_email_address, 
        ad.full_address, 
        cd.cd_gender, 
        cd.education 
    FROM 
        customer c 
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk 
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
)
SELECT 
    full_name, 
    c_email_address, 
    full_address, 
    cd_gender, 
    education 
FROM 
    CustomerDetails 
WHERE 
    education LIKE '%science%' 
ORDER BY 
    full_name;
