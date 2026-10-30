
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
DateStats AS (
    SELECT
        d_year,
        COUNT(DISTINCT d_date_sk) AS total_days,
        AVG(EXTRACT(DAY FROM d_date)) AS avg_day_of_month
    FROM date_dim
    GROUP BY d_year
),
WebSiteStats AS (
    SELECT
        web_country,
        COUNT(*) AS total_websites,
        AVG(LENGTH(web_name)) AS avg_website_name_length
    FROM web_site
    GROUP BY web_country
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.avg_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.avg_purchase_estimate,
    d.d_year,
    d.total_days,
    d.avg_day_of_month,
    w.web_country,
    w.total_websites,
    w.avg_website_name_length
FROM AddressStats a
JOIN CustomerStats c ON c.total_customers > 1000
JOIN DateStats d ON d.total_days > 200
JOIN WebSiteStats w ON w.total_websites > 50
ORDER BY a.ca_state, c.cd_gender, d.d_year, w.web_country;
