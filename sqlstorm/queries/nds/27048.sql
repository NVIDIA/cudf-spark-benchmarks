
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        COUNT(CASE WHEN ca_city LIKE '%city%' THEN 1 END) AS city_related_addresses
    FROM
        customer_address
    GROUP BY
        ca_state
),
DemographicStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        COUNT(CASE WHEN cd_credit_rating = 'Good' THEN 1 END) AS good_credit_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimates
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
SalesStats AS (
    SELECT
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        AVG(ws_quantity) AS avg_quantity_per_order
    FROM
        web_sales
    GROUP BY
        ws_ship_date_sk
)
SELECT
    ds.d_date AS sale_date,
    sa.ca_state,
    sa.unique_addresses,
    sa.avg_street_name_length,
    ss.total_sales,
    ss.num_orders,
    ss.avg_quantity_per_order,
    de.cd_gender,
    de.total_customers,
    de.avg_dependents,
    de.good_credit_count,
    de.total_purchase_estimates
FROM
    date_dim ds
JOIN
    SalesStats AS ss ON ds.d_date_sk = ss.ws_ship_date_sk
JOIN
    AddressStats AS sa ON sa.ca_state IN (
        SELECT ca_state FROM customer_address
    )
JOIN
    DemographicStats AS de ON de.cd_gender IN (
        SELECT cd_gender FROM customer_demographics
    )
WHERE
    ds.d_year = 2023
ORDER BY
    sale_date, sa.ca_state, de.cd_gender;
