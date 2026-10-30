
WITH Address_Stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(CAST(ca_zip AS DECIMAL)) AS avg_zip,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM customer_address
    GROUP BY ca_state
), 
Customer_Stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM customer_demographics
    GROUP BY cd_gender
), 
Date_Stats AS (
    SELECT 
        d_year,
        COUNT(*) AS date_count,
        COUNT(DISTINCT d_month_seq) AS unique_months,
        SUM(d_dom) AS total_days
    FROM date_dim
    GROUP BY d_year
)
SELECT 
    a.ca_state,
    a.address_count,
    a.avg_zip,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.total_dependents,
    d.d_year,
    d.date_count,
    d.unique_months,
    d.total_days
FROM Address_Stats a
JOIN Customer_Stats c ON a.address_count > 100
JOIN Date_Stats d ON d.date_count > 30 
ORDER BY a.ca_state, c.cd_gender, d.d_year;
