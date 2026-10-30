
WITH AddressMetrics AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY
        ca_state
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesMetrics AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        STRING_AGG(DISTINCT CAST(ws_order_number AS STRING), ', ') AS order_numbers
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    a.ca_state,
    a.address_count,
    a.cities,
    a.max_street_name_length,
    a.avg_street_name_length,
    d.cd_gender,
    d.demographic_count,
    d.education_levels,
    s.total_quantity_sold,
    s.total_net_profit,
    s.order_numbers
FROM 
    AddressMetrics a
JOIN 
    Demographics d ON a.address_count > 100
LEFT JOIN 
    SalesMetrics s ON a.address_count = s.ws_bill_addr_sk
ORDER BY 
    a.avg_street_name_length DESC, 
    d.demographic_count DESC;
