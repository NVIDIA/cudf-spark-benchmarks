
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        SUBSTR(ca_zip, 1, 5) AS zip_code_prefix
    FROM 
        customer_address
),
DemographicAnalysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band
    FROM 
        customer_demographics
),
AggregateData AS (
    SELECT 
        a.full_address,
        d.purchase_estimate_band,
        COUNT(d.cd_demo_sk) AS demographic_count
    FROM 
        AddressParts a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN 
        DemographicAnalysis d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY 
        a.full_address, d.purchase_estimate_band
),
FinalReport AS (
    SELECT 
        full_address,
        purchase_estimate_band,
        demographic_count,
        CASE 
            WHEN demographic_count > 10 THEN 'High Impact'
            WHEN demographic_count BETWEEN 5 AND 10 THEN 'Medium Impact'
            ELSE 'Low Impact'
        END AS address_impact_level
    FROM 
        AggregateData
    ORDER BY 
        demographic_count DESC
)
SELECT 
    full_address,
    purchase_estimate_band,
    demographic_count,
    address_impact_level
FROM 
    FinalReport
WHERE 
    address_impact_level = 'High Impact';
