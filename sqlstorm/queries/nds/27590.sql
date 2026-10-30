
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS count_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip
    FROM
        customer_address
    GROUP BY
        ca_state
),
CustomerCounts AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender
),
DateStats AS (
    SELECT
        d_year,
        COUNT(DISTINCT d_date_sk) AS unique_dates,
        COUNT(*) AS total_entries
    FROM
        date_dim
    GROUP BY
        d_year
),
StringBenchmarks AS (
    SELECT
        'Customer Address' AS source,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length
    FROM
        customer_address
    UNION ALL
    SELECT
        'Customer Demographics' AS source,
        COUNT(DISTINCT cd_demo_sk),
        SUM(LENGTH(cd_gender)) 
    FROM
        customer_demographics
    UNION ALL
    SELECT
        'Date Dimension' AS source,
        COUNT(DISTINCT d_date_id),
        SUM(LENGTH(d_day_name))
    FROM
        date_dim
)
SELECT
    a.ca_state,
    a.count_addresses,
    a.avg_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.avg_purchase_estimate,
    d.d_year,
    d.unique_dates,
    d.total_entries,
    s.source,
    s.unique_addresses,
    s.total_street_name_length
FROM
    AddressStats a
JOIN
    CustomerCounts c ON 1=1
JOIN
    DateStats d ON 1=1
JOIN
    StringBenchmarks s ON 1=1
ORDER BY
    a.ca_state, c.cd_gender, d.d_year, s.source;
