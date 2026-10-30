
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    A.ca_state,
    A.address_count,
    A.max_street_name_length,
    A.min_street_name_length,
    A.avg_street_name_length,
    C.cd_gender,
    C.customer_count,
    C.avg_purchase_estimate,
    C.total_dependents,
    S.ws_ship_date_sk,
    S.total_sales,
    S.order_count,
    S.avg_net_profit
FROM 
    AddressStats A
JOIN 
    CustomerStats C ON A.address_count > 100
JOIN 
    SalesStats S ON S.total_sales > 10000
ORDER BY 
    A.ca_state, C.cd_gender, S.total_sales DESC;
