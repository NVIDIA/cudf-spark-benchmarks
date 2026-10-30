
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) AS street_rank
    FROM 
        customer_address
    WHERE
        ca_street_name IS NOT NULL
),
AddressMetrics AS (
    SELECT 
        ca_city,
        MAX(LENGTH(ca_street_name)) AS max_street_length,
        MIN(LENGTH(ca_street_name)) AS min_street_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_length,
        COUNT(*) AS total_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    r.ca_city,
    r.street_rank,
    a.max_street_length,
    a.min_street_length,
    a.avg_street_length,
    c.cd_gender,
    c.customer_count,
    c.avg_dependents,
    c.avg_purchase_estimate
FROM 
    RankedAddresses r
JOIN 
    AddressMetrics a ON r.ca_city = a.ca_city
JOIN 
    CustomerDemographics c ON r.street_rank = 1
ORDER BY 
    a.max_street_length DESC, 
    c.customer_count DESC;
