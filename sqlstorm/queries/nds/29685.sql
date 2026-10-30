
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS unique_demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_ship_date_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
DemographicSales AS (
    SELECT 
        cs_bill_cdemo_sk AS customer_demo_id,
        SUM(cs_net_profit) AS total_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_cdemo_sk
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.unique_cities,
    A.avg_street_name_length,
    A.max_street_name_length,
    A.min_street_name_length,
    C.cd_gender,
    C.total_customers,
    C.avg_purchase_estimate,
    S.total_sales,
    S.total_net_profit,
    D.total_profit AS demographic_profit
FROM 
    AddressStats A
JOIN 
    CustomerStats C ON A.ca_state = 'CA' 
JOIN 
    SalesStats S ON S.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales) 
LEFT JOIN 
    DemographicSales D ON D.customer_demo_id = C.unique_demographics
WHERE 
    C.avg_purchase_estimate > 1000 
ORDER BY 
    A.total_addresses DESC, 
    C.total_customers DESC;
