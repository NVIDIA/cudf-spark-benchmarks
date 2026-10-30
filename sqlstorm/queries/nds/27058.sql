
WITH Address_Stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        CONCAT(MIN(ca_city), ' - ', MAX(ca_city)) AS city_range,
        AVG(COALESCE(NULLIF(LENGTH(ca_street_name), 0), 1)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographic_Stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Date_Stats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        COUNT(DISTINCT d_day_name) AS unique_days,
        AVG(d_dom) AS avg_day_of_month
    FROM 
        date_dim
    GROUP BY 
        d_year
),
Sales_Stats AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.city_range,
    A.avg_street_name_length,
    D.cd_gender,
    D.demographic_count,
    D.total_dependents,
    D.avg_purchase_estimate,
    DT.d_year,
    DT.total_dates,
    DT.unique_days,
    DT.avg_day_of_month,
    S.total_sales,
    S.total_net_profit,
    S.unique_orders
FROM 
    Address_Stats A
JOIN 
    Demographic_Stats D ON A.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = (SELECT MIN(ca_address_sk) FROM customer_address)) 
JOIN 
    Date_Stats DT ON DT.d_year = (SELECT MAX(d_year) FROM date_dim) 
JOIN 
    Sales_Stats S ON S.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales)
ORDER BY 
    A.ca_state, D.cd_gender, DT.d_year;
