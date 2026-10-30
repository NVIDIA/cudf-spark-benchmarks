
WITH AddressCounts AS (
    SELECT ca_state, COUNT(DISTINCT ca_city) AS unique_cities, 
           COUNT(DISTINCT ca_street_name) AS unique_streets
    FROM customer_address
    GROUP BY ca_state
),
DemographicsCounts AS (
    SELECT cd_gender, 
           SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
           SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
           AVG(cd_dep_count) AS avg_dependents
    FROM customer_demographics
    GROUP BY cd_gender
),
DateRanges AS (
    SELECT MIN(d_date) AS min_date, MAX(d_date) AS max_date
    FROM date_dim
    WHERE d_year = 2023
),
WebSiteStats AS (
    SELECT web_mkt_desc, COUNT(*) AS total_websites, 
           SUM(CASE WHEN web_open_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS open_websites
    FROM web_site
    GROUP BY web_mkt_desc
)
SELECT a.ca_state, a.unique_cities, a.unique_streets,
       d.cd_gender, d.married_count, d.single_count, d.avg_dependents,
       dr.min_date, dr.max_date,
       w.web_mkt_desc, w.total_websites, w.open_websites
FROM AddressCounts a
JOIN DemographicsCounts d ON d.cd_gender IN ('M', 'F')
CROSS JOIN DateRanges dr
JOIN WebSiteStats w ON w.total_websites > 10
ORDER BY a.ca_state, d.cd_gender;
