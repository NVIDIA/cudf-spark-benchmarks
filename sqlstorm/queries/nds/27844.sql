
WITH AddressAnalysis AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(ca_address_id) AS total_addresses,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM customer_address
    GROUP BY ca_state, ca_city
),
DemographicsAnalysis AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS total_demographics,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimates
    FROM customer_demographics
    GROUP BY cd_gender
),
SalesSummary AS (
    SELECT
        COALESCE(w.web_site_id, 'Unknown') AS web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY w.web_site_id
)
SELECT 
    aa.ca_state,
    aa.ca_city,
    aa.unique_addresses,
    aa.total_addresses,
    aa.total_street_name_length,
    aa.avg_street_name_length,
    da.cd_gender,
    da.total_demographics,
    da.avg_dependents,
    da.total_purchase_estimates,
    ss.total_sales,
    ss.avg_profit,
    ss.total_orders
FROM AddressAnalysis aa
JOIN DemographicsAnalysis da ON da.total_demographics > 10
JOIN SalesSummary ss ON ss.total_sales > 10000
ORDER BY aa.ca_state, aa.ca_city, da.cd_gender;
