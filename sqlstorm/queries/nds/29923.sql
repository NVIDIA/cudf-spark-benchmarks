
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT ca_zip) AS unique_zipcodes
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS unique_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_net_sales) AS total_web_sales,
        SUM(ss_net_sales) AS total_store_sales,
        SUM(cs_net_sales) AS total_catalog_sales
    FROM (
        SELECT 
            d_year,
            ws_net_paid AS ws_net_sales,
            0 AS ss_net_sales,
            0 AS cs_net_sales
        FROM 
            web_sales
        JOIN
            date_dim ON ws_sold_date_sk = d_date_sk
        UNION ALL
        SELECT 
            d_year,
            0 AS ws_net_sales,
            ss_net_paid AS ss_net_sales,
            0 AS cs_net_sales
        FROM 
            store_sales
        JOIN
            date_dim ON ss_sold_date_sk = d_date_sk
        UNION ALL
        SELECT 
            d_year,
            0 AS ws_net_sales,
            0 AS ss_net_sales,
            cs_net_paid AS cs_net_sales
        FROM 
            catalog_sales
        JOIN
            date_dim ON cs_sold_date_sk = d_date_sk
    ) AS all_sales
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.unique_cities,
    a.unique_zipcodes,
    d.cd_gender,
    d.unique_demographics,
    d.avg_purchase_estimate,
    d.max_dependents,
    s.d_year,
    s.total_web_sales,
    s.total_store_sales,
    s.total_catalog_sales
FROM 
    AddressSummary a
JOIN 
    DemographicSummary d ON 1=1
JOIN 
    SalesSummary s ON 1=1
ORDER BY 
    a.ca_state, d.cd_gender, s.d_year;
