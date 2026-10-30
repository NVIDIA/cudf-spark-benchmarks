
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_city IS NOT NULL THEN 1 ELSE 0 END) AS city_count,
        SUM(CASE WHEN ca_zip IS NOT NULL THEN 1 ELSE 0 END) AS zip_count
    FROM customer_address
    GROUP BY ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dep_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
CombinedStats AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.avg_street_name_length,
        a.city_count,
        a.zip_count,
        cd.cd_gender,
        cd.customer_count,
        cd.avg_dep_count,
        cd.avg_purchase_estimate
    FROM AddressStats a
    LEFT JOIN CustomerDemographics cd ON a.ca_state = 'NY' AND cd.customer_count > 1000
)
SELECT 
    ca_state,
    total_addresses,
    avg_street_name_length,
    city_count, 
    zip_count,
    cd_gender,
    customer_count,
    avg_dep_count,
    avg_purchase_estimate
FROM CombinedStats
ORDER BY total_addresses DESC, customer_count DESC;
