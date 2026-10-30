
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
)
SELECT
    a.ca_state,
    a.total_addresses,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.avg_dependents,
    c.total_purchase_estimate
FROM AddressStats a
JOIN CustomerStats c ON (a.total_addresses > 100 AND c.total_customers > 50)
ORDER BY a.ca_state, c.cd_gender;
