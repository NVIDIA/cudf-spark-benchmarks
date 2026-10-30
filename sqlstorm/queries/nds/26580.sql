
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS distinct_street_names
    FROM customer_address
    GROUP BY ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM customer_demographics
    GROUP BY cd_gender
),
SalesStats AS (
    SELECT 
        ws_sold_date_sk,
        COUNT(ws_order_number) AS total_web_sales,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_units_sold,
        STRING_AGG(DISTINCT CAST(ws_web_page_sk AS STRING), ', ') AS distinct_web_page_ids
    FROM web_sales
    GROUP BY ws_sold_date_sk
)

SELECT 
    a.ca_state,
    a.address_count,
    a.cities,
    a.distinct_street_names,
    d.cd_gender,
    d.demographic_count,
    d.education_levels,
    s.ws_sold_date_sk,
    s.total_web_sales,
    s.total_sales,
    s.total_units_sold,
    s.distinct_web_page_ids
FROM AddressStats a
JOIN DemographicsStats d ON d.demographic_count > 50
JOIN SalesStats s ON s.total_web_sales > 100
ORDER BY a.ca_state, d.cd_gender, s.ws_sold_date_sk;
