WITH AddressAnalysis AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_number) + LENGTH(ca_street_name) + LENGTH(ca_city) + LENGTH(ca_zip)) AS total_char_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
GenderAnalysis AS (
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
SalesAnalysis AS (
    SELECT 
        'web' AS sales_channel,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    UNION ALL
    SELECT 
        'store' AS sales_channel,
        COUNT(DISTINCT ss_ticket_number) AS total_orders,
        SUM(ss_sales_price) AS total_sales
    FROM 
        store_sales
)
SELECT 
    A.ca_state, 
    A.unique_addresses,
    A.total_char_count,
    G.cd_gender, 
    G.total_customers, 
    G.total_dependents, 
    G.avg_purchase_estimate,
    S.sales_channel,
    S.total_orders,
    S.total_sales
FROM 
    AddressAnalysis A
JOIN 
    GenderAnalysis G ON 1=1 
JOIN 
    SalesAnalysis S ON 1=1 
ORDER BY 
    A.ca_state, 
    G.cd_gender, 
    S.sales_channel;