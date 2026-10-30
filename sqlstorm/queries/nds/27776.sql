
WITH address_summary AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_street_name) AS unique_streets,
        SUM(LENGTH(ca_street_name) - LENGTH(REPLACE(ca_street_name, ' ', '')) + 1) AS total_word_count
    FROM
        customer_address
    GROUP BY
        ca_city, ca_state
),
customer_summary AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        SUM(cd_dep_count) AS total_dependencies,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender, cd_marital_status
)
SELECT
    a.ca_city,
    a.ca_state,
    a.unique_addresses,
    a.unique_streets,
    a.total_word_count,
    c.cd_gender,
    c.cd_marital_status,
    c.total_customers,
    c.total_dependencies,
    c.avg_purchase_estimate
FROM
    address_summary a
JOIN
    customer_summary c ON a.ca_state = c.cd_marital_status
ORDER BY
    a.ca_city, a.ca_state, c.total_customers DESC;
