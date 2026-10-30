
WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStatistics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStatistics AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    A.ca_state,
    A.unique_address_count,
    A.max_street_name_length,
    A.min_street_name_length,
    A.avg_street_name_length,
    C.cd_gender,
    C.total_customers,
    C.total_dependents,
    C.avg_purchase_estimate,
    S.total_orders,
    S.total_sales
FROM 
    AddressStatistics A
JOIN 
    CustomerStatistics C ON 1=1
JOIN 
    SalesStatistics S ON C.total_customers > 0
ORDER BY 
    A.ca_state, C.cd_gender;
