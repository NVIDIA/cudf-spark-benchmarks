
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
ProcessedDemographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ' - ', cd_marital_status, ' - ', cd_education_status) AS demographic_info,
        cd_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_dep_count > 0
),
AggregateSales AS (
    SELECT 
        ws_bill_cdemo_sk,
        COUNT(*) AS total_orders,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    r.ca_address_sk,
    r.ca_street_name,
    r.ca_city,
    r.ca_state,
    r.ca_country,
    d.demographic_info,
    a.total_orders,
    a.total_revenue
FROM 
    RankedAddresses r
JOIN 
    ProcessedDemographics d ON r.ca_address_sk = d.cd_demo_sk
JOIN 
    AggregateSales a ON d.cd_demo_sk = a.ws_bill_cdemo_sk
WHERE 
    r.city_rank <= 5
ORDER BY 
    r.ca_state, r.ca_city;
