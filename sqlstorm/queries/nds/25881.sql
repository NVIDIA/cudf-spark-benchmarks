
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(ca_zip) AS total_zips,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM customer_address
    GROUP BY ca_city
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_id) AS total_days,
        SUM(d_dom) AS total_days_in_month,
        MAX(d_week_seq) AS max_week_of_year
    FROM date_dim
    GROUP BY d_year
)
SELECT 
    a.ca_city,
    a.unique_addresses,
    a.total_zips,
    a.max_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.max_purchase_estimate,
    c.avg_dependents,
    d.d_year,
    d.total_days,
    d.total_days_in_month,
    d.max_week_of_year
FROM AddressStats a
JOIN CustomerStats c ON a.unique_addresses > 100
JOIN DateStats d ON d.total_days > 365
ORDER BY a.unique_addresses DESC, c.total_customers DESC;
