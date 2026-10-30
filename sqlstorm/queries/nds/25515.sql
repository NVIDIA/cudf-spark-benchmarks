
WITH AddressSummary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        COUNT(DISTINCT ca_zip) AS unique_zip_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
), 
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
DateSummary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS total_days,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holidays_count
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    A.ca_city,
    A.ca_state,
    A.address_count,
    A.unique_zip_count,
    C.cd_gender,
    C.cd_marital_status,
    C.cd_education_status,
    C.total_purchase_estimate,
    D.d_year,
    D.total_days,
    D.holidays_count
FROM 
    AddressSummary A
JOIN 
    CustomerDemographics C ON A.ca_city = 'New York' AND C.cd_gender = 'F'
JOIN 
    DateSummary D ON D.d_year = 2023
ORDER BY 
    A.address_count DESC, 
    C.total_purchase_estimate DESC;
