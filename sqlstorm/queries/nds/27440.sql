
WITH CustomerAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        UPPER(cd_education_status) AS edu_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F'
),
AggregatedData AS (
    SELECT 
        ca.ca_address_sk,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        cd.cd_demo_sk,
        cd.edu_status,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        CustomerAddress ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_address_sk, ca.full_address, ca.ca_city, ca.ca_state, cd.cd_demo_sk, cd.edu_status
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    edu_status,
    total_purchase_estimate
FROM 
    AggregatedData
WHERE 
    total_purchase_estimate > 1000
ORDER BY 
    ca_state, total_purchase_estimate DESC;
