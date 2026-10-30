
WITH AddressCityCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
), 
DemographicStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents,
        cd_demo_sk  -- Assuming cd_demo_sk should be included for joining later
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_demo_sk
), 
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    a.ca_city, 
    a.city_count, 
    d.cd_gender, 
    d.cd_marital_status, 
    d.demographic_count, 
    d.avg_purchase_estimate, 
    d.max_dependents, 
    s.total_profit, 
    s.total_quantity
FROM 
    AddressCityCounts a
JOIN 
    DemographicStats d ON a.city_count = d.demographic_count
LEFT JOIN 
    SalesData s ON d.cd_demo_sk = s.ws_bill_cdemo_sk
WHERE 
    a.city_count > 10 AND 
    d.avg_purchase_estimate > 500
ORDER BY 
    a.city_count DESC, 
    s.total_profit DESC;
