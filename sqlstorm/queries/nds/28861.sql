
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        SUM(LENGTH(ca_street_name) - LENGTH(REPLACE(ca_street_name, ' ', '')) + 1) AS word_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dep_count,
        MIN(cd_dep_college_count) AS min_college_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesInfo AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ac.ca_state,
    ac.address_count,
    ac.word_count,
    ds.cd_gender,
    ds.avg_purchase_estimate,
    ds.max_dep_count,
    ds.min_college_count,
    si.w_warehouse_name,
    si.total_sales,
    si.total_orders
FROM 
    AddressCounts AS ac
JOIN 
    DemographicStats AS ds ON ac.address_count > 100
JOIN 
    SalesInfo AS si ON ac.address_count < 500
WHERE 
    ds.avg_purchase_estimate > 2000
ORDER BY 
    ac.word_count DESC,
    si.total_sales DESC;
