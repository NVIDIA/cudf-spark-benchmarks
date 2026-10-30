WITH AddressData AS (
    SELECT 
        ca_city, 
        ca_state, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
        LENGTH(CAST(ca_zip AS STRING)) AS zip_length
    FROM 
        customer_address
),
DemographicsData AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        COUNT(*) AS count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
),
AggregateData AS (
    SELECT 
        ad.ca_city, 
        ad.ca_state, 
        ad.full_address, 
        ad.zip_length, 
        dg.cd_gender, 
        dg.cd_marital_status, 
        dg.cd_education_status,
        dg.count,
        ROW_NUMBER() OVER (PARTITION BY ad.ca_city, dg.cd_gender ORDER BY dg.count DESC) AS rank
    FROM 
        AddressData ad
    JOIN 
        DemographicsData dg ON ad.ca_state = dg.cd_marital_status  
)
SELECT 
    ca_city, 
    ca_state, 
    full_address, 
    zip_length, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status 
FROM 
    AggregateData
WHERE 
    rank <= 5 
ORDER BY 
    ca_city, 
    cd_gender;