
WITH AddressMetrics AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip
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
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesMetrics AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    A.ca_state,
    A.address_count,
    A.avg_street_name_length,
    C.cd_gender,
    C.customer_count,
    C.avg_dep_count,
    S.ws_ship_date_sk,
    S.total_sales,
    S.total_orders,
    S.total_net_profit
FROM 
    AddressMetrics A
JOIN 
    CustomerMetrics C ON A.address_count > 100
JOIN 
    SalesMetrics S ON S.total_sales > 10000
ORDER BY 
    A.ca_state, C.cd_gender, S.ws_ship_date_sk;
