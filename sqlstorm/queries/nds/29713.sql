
WITH CustomerFullNames AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregatedDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cfn.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        CustomerFullNames cfn
    JOIN 
        customer_demographics cd ON cfn.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
PopularCities AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS city_customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
    HAVING 
        COUNT(DISTINCT c.c_customer_sk) > 100
)
SELECT 
    ad.cd_gender,
    ad.cd_marital_status,
    ad.customer_count,
    ad.avg_purchase_estimate,
    pc.ca_city,
    pc.city_customer_count
FROM 
    AggregatedDemographics ad
JOIN 
    PopularCities pc ON ad.customer_count > 50
ORDER BY 
    ad.cd_gender, ad.cd_marital_status, pc.city_customer_count DESC
LIMIT 10;
