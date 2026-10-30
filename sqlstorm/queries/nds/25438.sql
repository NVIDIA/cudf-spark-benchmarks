
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca_street_name, ' ', ca_street_type, ' ', ca_street_number), ', ') AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
), DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), SalesStatistics AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        STRING_AGG(DISTINCT CAST(ws_order_number AS STRING), ', ') AS order_numbers
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    a.ca_city,
    a.address_count,
    a.unique_addresses,
    d.cd_gender,
    d.demographic_count,
    d.avg_purchase,
    d.marital_statuses,
    s.total_sales,
    s.avg_net_profit,
    s.order_numbers
FROM 
    AddressCounts a
JOIN 
    DemographicStats d ON a.address_count > 100
JOIN 
    SalesStatistics s ON a.ca_city = 'New York' 
ORDER BY 
    a.address_count DESC, d.demographic_count DESC;
