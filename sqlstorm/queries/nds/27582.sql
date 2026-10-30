
WITH AddressAnalysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_city LIKE '%ville%' THEN 1 ELSE 0 END) AS ville_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
), 
DemographicsAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_credit_rating = 'Fair' THEN 1 ELSE 0 END) AS fair_credit_count
    FROM 
        customer_demographics
    JOIN 
        customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, 
        cd_marital_status
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.ville_count,
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count,
    d.avg_purchase_estimate,
    d.fair_credit_count
FROM 
    AddressAnalysis a
JOIN 
    DemographicsAnalysis d ON a.ca_state = d.cd_marital_status
ORDER BY 
    a.ca_city, 
    d.cd_gender;
