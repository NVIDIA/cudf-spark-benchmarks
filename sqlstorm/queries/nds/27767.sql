
WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerStatistics AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(c_customer_sk) AS total_customers,
        MAX(cd_dep_count) AS max_dependents
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender
),
FullStatistics AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.unique_cities,
        a.avg_street_name_length,
        a.max_street_name_length,
        a.min_street_name_length,
        c.cd_gender,
        c.avg_purchase_estimate,
        c.total_customers,
        c.max_dependents
    FROM AddressStatistics a
    JOIN CustomerStatistics c ON c.total_customers > 0
)
SELECT 
    fs.ca_state,
    fs.total_addresses,
    fs.unique_cities,
    fs.avg_street_name_length,
    fs.max_street_name_length,
    fs.min_street_name_length,
    fs.cd_gender,
    fs.avg_purchase_estimate,
    fs.total_customers,
    fs.max_dependents
FROM FullStatistics fs
ORDER BY fs.total_addresses DESC, fs.avg_purchase_estimate DESC
LIMIT 10;
