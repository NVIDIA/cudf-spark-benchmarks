
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length
    FROM customer_address
),
FilteredAddresses AS (
    SELECT 
        *,
        LENGTH(full_address) AS full_address_length
    FROM AddressParts
    WHERE ca_state = 'CA' AND ca_zip LIKE '9%'
),
AddressBenchmark AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        AVG(street_name_length) AS avg_street_name_length,
        AVG(city_length) AS avg_city_length,
        AVG(state_length) AS avg_state_length,
        AVG(full_address_length) AS avg_full_address_length
    FROM FilteredAddresses
    GROUP BY ca_city
)
SELECT 
    ab.ca_city,
    ab.address_count,
    ab.avg_street_name_length,
    ab.avg_city_length,
    ab.avg_state_length,
    ab.avg_full_address_length,
    cd.cd_gender,
    cd.cd_marital_status
FROM AddressBenchmark ab
JOIN customer_demographics cd ON ab.address_count = cd.cd_demo_sk
WHERE cd.cd_purchase_estimate > 1000
ORDER BY ab.address_count DESC, ab.ca_city;
