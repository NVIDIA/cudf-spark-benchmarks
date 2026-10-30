
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM
        customer_address
    GROUP BY
        ca_state
),
DemographicStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_credit_rating) AS unique_credit_ratings
    FROM
        customer_demographics
    GROUP BY
        cd_gender
)
SELECT
    a.ca_state,
    a.total_addresses,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    d.cd_gender,
    d.total_demographics,
    d.avg_purchase_estimate,
    d.unique_credit_ratings
FROM
    AddressStats a
JOIN
    DemographicStats d ON a.total_addresses > 1000
ORDER BY
    a.total_addresses DESC, d.total_demographics DESC;
