
WITH AddressCounts AS (
    SELECT
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(CASE WHEN ca_city IS NOT NULL THEN 1 END) AS city_addresses,
        COUNT(CASE WHEN ca_street_name IS NOT NULL AND ca_street_number IS NOT NULL THEN 1 END) AS street_addresses
    FROM customer_address
    GROUP BY ca_state
),
StringStats AS (
    SELECT
        w_state,
        AVG(LENGTH(w_warehouse_name)) AS avg_warehouse_name_length,
        MAX(LENGTH(w_country)) AS max_country_length,
        SUM(CASE WHEN LENGTH(w_warehouse_name) > 30 THEN 1 ELSE 0 END) AS long_names_count
    FROM warehouse
    GROUP BY w_state
),
CustomerGenderAlerts AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN cd_purchase_estimate > 1000 THEN 1 ELSE 0 END) AS high_value_customers
    FROM customer_demographics
    GROUP BY cd_gender
)
SELECT
    ac.ca_state,
    ac.total_addresses,
    ac.city_addresses,
    ac.street_addresses,
    ss.avg_warehouse_name_length,
    ss.max_country_length,
    ss.long_names_count,
    cga.cd_gender,
    cga.total_customers,
    cga.high_value_customers
FROM AddressCounts ac
JOIN StringStats ss ON ac.ca_state = ss.w_state
JOIN CustomerGenderAlerts cga ON cga.total_customers > 50
ORDER BY ac.total_addresses DESC, cga.total_customers DESC;
