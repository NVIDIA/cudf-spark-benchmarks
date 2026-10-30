
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(
            TRIM(ca_street_number), ' ', 
            TRIM(ca_street_name), ' ', 
            TRIM(ca_street_type), ', ', 
            TRIM(ca_city), ', ', 
            TRIM(ca_state), ' ', 
            TRIM(ca_zip), ' - ', 
            TRIM(ca_country)
        ) AS FullAddress,
        LENGTH(TRIM(ca_street_name)) AS StreetNameLength,
        UPPER(TRIM(ca_city)) AS UpperCity
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CHAR_LENGTH(TRIM(cd_credit_rating)) AS CreditRatingLength
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 5000
),
CombinedData AS (
    SELECT 
        pa.ca_address_sk,
        pa.FullAddress,
        pa.StreetNameLength,
        pa.UpperCity,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_education_status,
        dem.cd_purchase_estimate,
        dem.CreditRatingLength
    FROM 
        ProcessedAddresses AS pa
    JOIN 
        Demographics AS dem ON pa.ca_address_sk = dem.cd_demo_sk
)
SELECT 
    UpperCity,
    COUNT(*) AS TotalAddresses,
    AVG(StreetNameLength) AS AvgStreetNameLength,
    AVG(CreditRatingLength) AS AvgCreditRatingLength,
    SUM(cd_purchase_estimate) AS TotalPurchaseEstimate
FROM 
    CombinedData
GROUP BY 
    UpperCity
ORDER BY 
    TotalAddresses DESC
LIMIT 10;
