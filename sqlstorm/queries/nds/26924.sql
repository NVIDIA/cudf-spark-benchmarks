
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state
    FROM 
        customer_address 
    WHERE 
        ca_country = 'USA'
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
    WHERE 
        cd_credit_rating IN ('High', 'Medium')
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        ca.full_address,
        ca.city,
        ca.state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    full_name,
    full_address,
    city,
    state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) OVER(PARTITION BY cd_gender) AS gender_count,
    COUNT(*) OVER(PARTITION BY cd_marital_status) AS marital_status_count
FROM 
    CustomerInfo
ORDER BY 
    city, state, full_name;
