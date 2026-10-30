
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(COALESCE(NULLIF(LENGTH(ca_street_name), 0), NULL)) AS avg_street_name_length
    FROM customer_address
    WHERE ca_country = 'USA'
    GROUP BY ca_state
),
GenderStats AS (
    SELECT
        cd_gender,
        COUNT(cd_demo_sk) AS demographic_count,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
CombinedStats AS (
    SELECT
        A.ca_state,
        A.unique_addresses,
        A.avg_street_name_length,
        G.cd_gender,
        G.demographic_count,
        G.avg_dependents,
        G.avg_purchase_estimate
    FROM AddressStats A
    CROSS JOIN GenderStats G
),
TopStates AS (
    SELECT
        ca_state,
        RANK() OVER (ORDER BY unique_addresses DESC) AS state_rank
    FROM AddressStats
)
SELECT
    C.ca_state,
    C.unique_addresses,
    C.avg_street_name_length,
    C.cd_gender,
    C.demographic_count,
    C.avg_dependents,
    C.avg_purchase_estimate
FROM CombinedStats C
JOIN TopStates T ON C.ca_state = T.ca_state
WHERE T.state_rank <= 5
ORDER BY C.unique_addresses DESC, C.cd_gender;
