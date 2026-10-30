
WITH CustomerAddressDistricts AS (
    SELECT DISTINCT 
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
), 
CustomerDemographicsGender AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), 
CustomerAnalysis AS (
    SELECT 
        cad.full_address,
        cdg.cd_gender,
        cdg.gender_count,
        cdg.avg_purchase_estimate,
        cad.street_name_length
    FROM 
        CustomerAddressDistricts cad
    JOIN 
        CustomerDemographicsGender cdg ON cad.full_address IS NOT NULL
)
SELECT 
    CONCAT(full_address, ' | ', cd_gender) AS customer_info,
    gender_count,
    avg_purchase_estimate,
    street_name_length
FROM 
    CustomerAnalysis
WHERE 
    street_name_length > 20 
GROUP BY 
    full_address, cd_gender, gender_count, avg_purchase_estimate, street_name_length
ORDER BY 
    avg_purchase_estimate DESC
LIMIT 10;
