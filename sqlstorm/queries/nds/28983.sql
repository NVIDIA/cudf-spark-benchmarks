
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(', ', TRIM(ca.ca_street_number), TRIM(ca.ca_street_name), TRIM(ca.ca_street_type), TRIM(ca.ca_suite_number), TRIM(ca.ca_city), TRIM(ca.ca_state), TRIM(ca.ca_zip), TRIM(ca.ca_country)) AS full_address
    FROM 
        customer_address ca
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Female' 
        END AS gender,
        cd.cd_marital_status, 
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer_demographics cd
),
AddressWithDemographics AS (
    SELECT 
        cad.full_address,
        cd.gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        CustomerAddressDetails cad
    JOIN 
        customer c ON cad.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    full_address,
    COUNT(*) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    AddressWithDemographics
GROUP BY 
    full_address
ORDER BY 
    total_customers DESC
LIMIT 10;
