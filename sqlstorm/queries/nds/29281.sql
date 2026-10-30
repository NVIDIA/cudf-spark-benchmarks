
WITH Address_Stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographic_Stats AS (
    SELECT 
        cd_gender,
        AVG(cd_dep_count) AS avg_dependents,
        COUNT(*) AS total_demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Sales_Analysis AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.unique_cities,
    A.total_street_name_length,
    A.avg_street_name_length,
    D.cd_gender,
    D.avg_dependents,
    D.total_demographics,
    S.ws_ship_date_sk,
    S.total_sales,
    S.total_orders
FROM 
    Address_Stats A
JOIN 
    Demographic_Stats D ON A.total_addresses > 100
JOIN 
    Sales_Analysis S ON S.total_sales > 1000
ORDER BY 
    A.ca_state, D.cd_gender, S.ws_ship_date_sk DESC;
