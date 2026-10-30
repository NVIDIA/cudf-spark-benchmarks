
WITH AddressInfo AS (
    SELECT 
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country, 
        LENGTH(ca_street_name) AS street_name_length, 
        LOWER(ca_street_name) AS lower_street_name, 
        REGEXP_REPLACE(ca_street_name, '[^a-zA-Z0-9 ]', '') AS cleaned_street_name 
    FROM customer_address
),
GenderDemographics AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS gender_count, 
        AVG(cd_purchase_estimate) AS avg_purchase
    FROM customer_demographics
    GROUP BY cd_gender
),
DateAnalysis AS (
    SELECT 
        d_year, 
        d_dow, 
        COUNT(*) AS total_days, 
        SUM(CASE WHEN d_current_year = 'Y' THEN 1 ELSE 0 END) AS current_year_count
    FROM date_dim
    GROUP BY d_year, d_dow
),
SalesData AS (
    SELECT 
        'web' AS sales_channel, 
        ws_ship_date_sk AS sales_date, 
        SUM(ws_sales_price) AS total_sales 
    FROM web_sales 
    GROUP BY ws_ship_date_sk 
    UNION ALL 
    SELECT 
        'store' AS sales_channel, 
        ss_sold_date_sk AS sales_date, 
        SUM(ss_sales_price) AS total_sales 
    FROM store_sales 
    GROUP BY ss_sold_date_sk 
),
SalesComparison AS (
    SELECT 
        sales_channel, 
        sales_date,
        SUM(total_sales) AS sales_total 
    FROM SalesData 
    GROUP BY sales_channel, sales_date
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    gd.cd_gender,
    da.d_year,
    sc.sales_channel,
    sc.sales_total
FROM AddressInfo ai 
JOIN GenderDemographics gd ON ai.ca_country LIKE '%US%'
JOIN DateAnalysis da ON da.total_days > 0
JOIN SalesComparison sc ON sc.sales_date = da.d_year
WHERE ai.street_name_length > 10
GROUP BY 
    ai.ca_city,
    ai.ca_state,
    gd.cd_gender,
    da.d_year,
    sc.sales_channel,
    sc.sales_total
ORDER BY sc.sales_total DESC, ai.ca_city, gd.cd_gender;
