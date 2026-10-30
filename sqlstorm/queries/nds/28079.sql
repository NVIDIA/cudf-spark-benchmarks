
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS address_with_city_state_zip,
        ca_country
    FROM 
        customer_address
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        COUNT(c_customer_sk) AS customer_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk
),
SalesStatistics AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ad.full_address,
    ad.address_with_city_state_zip,
    ad.ca_country,
    cd.customer_count,
    cd.max_purchase_estimate,
    cd.min_purchase_estimate,
    cd.avg_purchase_estimate,
    ss.total_sales,
    ss.total_profit
FROM 
    AddressDetails ad
LEFT JOIN 
    CustomerDemographics cd ON ad.ca_address_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesStatistics ss ON cd.cd_demo_sk = ss.ws_bill_cdemo_sk
WHERE 
    ad.ca_country = 'USA'
ORDER BY 
    total_sales DESC, 
    cd.avg_purchase_estimate DESC
LIMIT 100;
