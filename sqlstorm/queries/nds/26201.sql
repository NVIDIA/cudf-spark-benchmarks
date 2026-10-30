
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
DemographicStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_dep_count) AS avg_dep_count,
        AVG(cd_dep_employed_count) AS avg_employed_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
DateStats AS (
    SELECT
        EXTRACT(YEAR FROM d_date) AS year,
        COUNT(*) AS total_dates,
        COUNT(DISTINCT d_month_seq) AS unique_months,
        AVG(d_dom) AS avg_day_of_month
    FROM date_dim
    GROUP BY year
),
WarehouseSummary AS (
    SELECT
        w_state,
        COUNT(*) AS total_warehouses,
        AVG(w_warehouse_sq_ft) AS avg_square_feet,
        MAX(w_warehouse_sq_ft) AS max_square_feet,
        MIN(w_warehouse_sq_ft) AS min_square_feet
    FROM warehouse
    GROUP BY w_state
)
SELECT
    A.ca_state,
    A.total_addresses,
    A.avg_street_name_length,
    D.cd_gender,
    D.total_demographics,
    D.avg_dep_count,
    D.avg_employed_count,
    D.avg_purchase_estimate,
    DS.year,
    DS.total_dates,
    DS.unique_months,
    DS.avg_day_of_month,
    W.total_warehouses,
    W.avg_square_feet,
    W.max_square_feet,
    W.min_square_feet
FROM AddressStats A
JOIN DemographicStats D ON D.total_demographics > 10
JOIN DateStats DS ON DS.total_dates > 2000
JOIN WarehouseSummary W ON W.total_warehouses > 5
ORDER BY A.ca_state, D.cd_gender, DS.year;
