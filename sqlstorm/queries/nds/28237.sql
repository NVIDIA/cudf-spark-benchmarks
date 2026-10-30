
WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS num_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
AggregatedStatistics AS (
    SELECT 
        CONCAT('State: ', a.ca_state, 
               ' | Total Addresses: ', a.total_addresses,
               ' | Unique Cities: ', a.unique_cities, 
               ' | Max Street Name Length: ', a.max_street_name_length,
               ' | Avg Street Name Length: ', ROUND(a.avg_street_name_length, 2),
               ' | Gender: ', c.cd_gender, 
               ' | Number of Customers: ', c.num_customers,
               ' | Avg Purchase Estimate: ', ROUND(c.avg_purchase_estimate, 2)) AS summary
    FROM 
        AddressStatistics a
    JOIN 
        CustomerDemographics c ON a.ca_state IS NOT NULL
)
SELECT 
    summary
FROM 
    AggregatedStatistics
ORDER BY 
    summary;
