
WITH AddressAnalysis AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_state) AS lower_state
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
        cd_dep_college_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender IN ('M', 'F')
),
AggregatedData AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        c.cd_gender,
        c.cd_marital_status,
        COUNT(c.cd_demo_sk) AS demographic_count,
        AVG(c.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        AddressAnalysis a
    JOIN 
        CustomerDemographics c ON a.ca_address_sk = c.cd_demo_sk
    GROUP BY 
        a.full_address, a.ca_city, a.ca_state, a.ca_zip, c.cd_gender, c.cd_marital_status
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    demographic_count,
    avg_purchase_estimate,
    CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital_status,
    CASE 
        WHEN avg_purchase_estimate IS NULL THEN 'No Data'
        WHEN avg_purchase_estimate > 1000 THEN 'High Spend'
        ELSE 'Low Spend'
    END AS spending_category
FROM 
    AggregatedData
ORDER BY 
    ca_city, demographic_count DESC;
