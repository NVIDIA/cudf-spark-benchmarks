
WITH Address_City AS (
    SELECT DISTINCT 
        ca_city, 
        COUNT(ca_address_sk) AS city_address_count,
        COUNT(DISTINCT ca_country) AS unique_countries
    FROM customer_address
    GROUP BY ca_city
),
Demo_Gender AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM customer_demographics
    GROUP BY cd_gender
),
Date_Info AS (
    SELECT 
        d_year, 
        COUNT(d_date_sk) AS total_days_in_year
    FROM date_dim
    GROUP BY d_year
),
Sales_Statistics AS (
    SELECT 
        sm_carrier, 
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    JOIN ship_mode ON ws_ship_mode_sk = sm_ship_mode_sk
    GROUP BY sm_carrier
),
Combined_Results AS (
    SELECT 
        a.ca_city, 
        a.city_address_count,
        a.unique_countries,
        d.d_year,
        d.total_days_in_year,
        g.cd_gender,
        g.avg_purchase_estimate,
        g.total_dependents,
        s.sm_carrier,
        s.total_orders,
        s.total_net_profit
    FROM Address_City a
    CROSS JOIN Date_Info d
    JOIN Demo_Gender g ON g.cd_gender IN ('M', 'F')
    JOIN Sales_Statistics s ON s.total_orders > 100
)
SELECT 
    *,
    CONCAT('City: ', ca_city, ', Year: ', d_year) AS city_year,
    CONCAT('Total Orders: ', total_orders, ', Total Net Profit: ', total_net_profit) AS sales_summary
FROM Combined_Results
ORDER BY ca_city, d_year;
