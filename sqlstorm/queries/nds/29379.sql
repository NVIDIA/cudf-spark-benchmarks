
WITH AddressMetrics AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        STRING_AGG(DISTINCT ca_city, ', ') AS city_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerMetrics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_dep_count) AS avg_dep_count,
        MIN(cd_dep_count) AS min_dep_count,
        MAX(cd_dep_count) AS max_dep_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesMetrics AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_quantity) AS avg_items_per_order,
        STRING_AGG(DISTINCT CAST(ws_ship_mode_sk AS STRING), ', ') AS ship_modes_used
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
)
SELECT 
    A.ca_state,
    A.address_count,
    A.avg_street_name_length,
    A.min_street_name_length,
    A.max_street_name_length,
    A.city_list,
    C.cd_gender,
    C.customer_count,
    C.avg_dep_count,
    C.min_dep_count,
    C.max_dep_count,
    S.ws_sold_date_sk,
    S.total_sales,
    S.total_orders,
    S.avg_items_per_order,
    S.ship_modes_used
FROM 
    AddressMetrics A
JOIN 
    CustomerMetrics C ON C.customer_count > 100
JOIN 
    SalesMetrics S ON S.total_sales > 1000
ORDER BY 
    A.ca_state, C.cd_gender, S.total_sales DESC;
