
WITH CustomerFullNames AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        d.d_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ' ', TRIM(ca.ca_street_type), 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' ', TRIM(ca.ca_suite_number)) ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
DemographicsWithAddress AS (
    SELECT 
        cf.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        cf.cd_gender,
        cf.cd_marital_status,
        cf.cd_education_status,
        COUNT(*) OVER (PARTITION BY ad.ca_city, ad.ca_state) AS city_population
    FROM 
        CustomerFullNames cf
    JOIN 
        AddressDetails ad ON cf.c_customer_sk = ad.ca_address_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    city_population
FROM 
    DemographicsWithAddress
WHERE 
    cd_gender = 'F' AND
    cd_marital_status = 'M'
ORDER BY 
    city_population DESC,
    full_name ASC
LIMIT 100;
