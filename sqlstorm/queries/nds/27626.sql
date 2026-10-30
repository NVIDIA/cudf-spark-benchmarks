
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN LENGTH(ca_street_name) > 50 THEN 1 ELSE 0 END) AS long_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_credit_rating = 'Standard' THEN 1 ELSE 0 END) AS standard_credit_ratings
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.avg_street_name_length,
    a.long_street_names,
    c.cd_gender,
    c.total_customers,
    c.avg_purchase_estimate,
    c.standard_credit_ratings
FROM 
    AddressStats a
JOIN 
    CustomerDemographics c ON a.total_addresses > 1000
ORDER BY 
    a.total_addresses DESC, 
    c.total_customers DESC;
