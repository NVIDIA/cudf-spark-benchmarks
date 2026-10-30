
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
FilteredDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 5000 
        AND cd_gender = 'F'
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.full_address,
        cd.cd_gender,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        RankedAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        FilteredDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    ci.cd_gender,
    ci.cd_purchase_estimate,
    LENGTH(ci.full_address) AS address_length
FROM 
    CustomerInfo ci
WHERE 
    ci.cd_purchase_estimate BETWEEN 6000 AND 12000
ORDER BY 
    address_length DESC
LIMIT 100;
