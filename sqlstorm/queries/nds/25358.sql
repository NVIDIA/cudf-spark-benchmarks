
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM
        customer_address
    GROUP BY
        ca_state
),
Demographics AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_dep_count) AS avg_dependents,
        COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS married_count,
        COUNT(CASE WHEN cd_marital_status = 'S' THEN 1 END) AS single_count
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
DateStats AS (
    SELECT
        d_year,
        COUNT(*) AS total_days,
        COUNT(CASE WHEN d_holiday = 'Y' THEN 1 END) AS holiday_count,
        AVG(d_dom) AS avg_day_of_month,
        MAX(d_dom) AS max_day_of_month,
        MIN(d_dom) AS min_day_of_month
    FROM
        date_dim
    GROUP BY
        d_year
),
WarehouseDetails AS (
    SELECT
        w_state,
        SUM(w_warehouse_sq_ft) AS total_sq_ft,
        COUNT(*) AS total_warehouses
    FROM
        warehouse
    GROUP BY
        w_state
)
SELECT
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    d.cd_gender,
    d.total_demographics,
    d.avg_dependents,
    d.married_count,
    d.single_count,
    dt.d_year,
    dt.total_days,
    dt.holiday_count,
    dt.avg_day_of_month,
    dt.max_day_of_month,
    dt.min_day_of_month,
    w.w_state,
    w.total_sq_ft,
    w.total_warehouses
FROM
    AddressStats a
JOIN
    Demographics d ON a.ca_state = d.cd_gender
JOIN
    DateStats dt ON dt.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
JOIN
    WarehouseDetails w ON a.ca_state = w.w_state
ORDER BY
    a.ca_state, d.cd_gender, dt.d_year, w.total_sq_ft DESC;
