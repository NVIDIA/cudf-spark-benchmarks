WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_city)) AS max_city_name_length,
        MIN(LENGTH(ca_zip)) AS min_zip_length
    FROM customer_address
    GROUP BY ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_college_count) AS total_college_dependents
    FROM customer_demographics
    GROUP BY cd_gender
),
OrderStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.avg_street_name_length,
    A.max_city_name_length,
    A.min_zip_length,
    D.cd_gender,
    D.total_demographics,
    D.avg_purchase_estimate,
    D.total_dependents,
    D.total_college_dependents,
    O.total_quantity,
    O.total_sales,
    O.avg_net_profit
FROM AddressStats A
JOIN DemographicStats D ON D.total_demographics > 100  
JOIN OrderStats O ON O.total_quantity > 10  
ORDER BY A.total_addresses DESC, D.total_demographics DESC;