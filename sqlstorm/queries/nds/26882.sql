
WITH AddressDetails AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(CASE WHEN LOWER(ca_street_type) LIKE '%ave%' THEN 1 ELSE 0 END) AS ave_streets,
        SUM(CASE WHEN LOWER(ca_street_type) LIKE '%st%' THEN 1 ELSE 0 END) AS st_streets,
        SUM(CASE WHEN LOWER(ca_street_type) LIKE '%blvd%' THEN 1 ELSE 0 END) AS blvd_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
CitySummary AS (
    SELECT 
        ad.ca_city,
        ad.unique_addresses,
        cd.demographic_count,
        cd.avg_purchase_estimate
    FROM 
        AddressDetails ad
    JOIN 
        CustomerDemographics cd ON ad.ca_city = cd.cd_gender
)
SELECT 
    cs.ca_city,
    cs.unique_addresses,
    COALESCE(cs.demographic_count, 0) AS demographic_count,
    COALESCE(cs.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    CONCAT(cs.ca_city, ' has ', cs.unique_addresses, ' unique addresses, ', 
           COALESCE(cs.demographic_count, 0), ' demographics, and an average purchase estimate of $', 
           ROUND(COALESCE(cs.avg_purchase_estimate, 0), 2)) AS summary
FROM 
    CitySummary cs
ORDER BY 
    cs.unique_addresses DESC;
