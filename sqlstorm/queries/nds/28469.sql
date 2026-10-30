
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number))
                   ELSE ''
               END) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS customer_name,
        d.d_date AS registration_date,
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
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(ca_address_sk) AS address_count
    FROM 
        AddressDetails
    GROUP BY 
        ca_state
)
SELECT 
    ci.customer_name,
    ci.registration_date,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ad.full_address,
    ac.address_count
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.c_customer_sk = ad.ca_address_sk
JOIN 
    AddressCounts ac ON ad.ca_state = ac.ca_state
WHERE 
    ci.registration_date >= '2022-01-01' 
ORDER BY 
    ac.address_count DESC, 
    ci.customer_name ASC
LIMIT 100;
