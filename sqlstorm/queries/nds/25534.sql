
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(
            TRIM(ca_street_number), ' ',
            TRIM(ca_street_name), ' ',
            TRIM(ca_street_type), 
            CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number != '' THEN CONCAT(', Suite ', TRIM(ca_suite_number)) ELSE '' END
        ) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM customer_address
),

CustomerStatistics AS (
    SELECT
        cd_demo_sk,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_demo_sk
)

SELECT
    ad.full_address,
    ad.city,
    ad.state,
    ad.zip,
    cs.total_customers,
    cs.male_count,
    cs.female_count,
    cs.avg_purchase_estimate
FROM AddressDetails ad
JOIN CustomerStatistics cs ON ad.ca_address_sk = cs.cd_demo_sk
WHERE ad.state = 'CA'
ORDER BY cs.total_customers DESC
LIMIT 100;
