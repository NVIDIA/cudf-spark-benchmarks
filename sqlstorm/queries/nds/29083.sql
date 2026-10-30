
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
), 
CombinedData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.full_address,
    c.cd_gender,
    c.cd_marital_status,
    COUNT(*) OVER (PARTITION BY c.cd_gender) AS gender_count,
    COUNT(*) OVER (PARTITION BY c.cd_marital_status) AS marital_count
FROM 
    CombinedData c
WHERE 
    c.cd_education_status LIKE '%Graduate%'
ORDER BY 
    c.c_last_name, c.c_first_name;
