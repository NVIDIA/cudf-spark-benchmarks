
WITH AddressGroups AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    WHERE ca_country = 'USA'
    GROUP BY ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependent_count,
        SUM(cd_dep_employed_count) AS total_employed_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT 
    AG.ca_city,
    AG.ca_state,
    AG.address_count,
    AG.avg_gmt_offset,
    CD.cd_gender,
    CD.cd_marital_status,
    CD.total_dependent_count,
    CD.total_employed_count,
    CD.avg_purchase_estimate,
    SD.total_net_profit,
    SD.total_orders
FROM AddressGroups AG
JOIN CustomerDemographics CD ON CD.total_dependent_count > 0
JOIN SalesData SD ON SD.ws_bill_cdemo_sk IS NOT NULL
WHERE AG.address_count > 10
ORDER BY AG.ca_city, AG.ca_state, CD.cd_gender;
