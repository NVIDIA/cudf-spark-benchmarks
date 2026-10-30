WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        COUNT(DISTINCT ca_city) AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS total_demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
),
CombinedStats AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.avg_street_name_length,
        a.unique_cities,
        d.cd_gender,
        d.avg_purchase_estimate,
        d.total_demographics,
        s.total_sales,
        s.total_orders
    FROM 
        AddressStats a
    LEFT JOIN 
        DemographicStats d ON a.total_addresses > 0  
    LEFT JOIN 
        SalesStats s ON a.total_addresses > 0  
)
SELECT 
    *,
    CONCAT(ca_state, ' has ', total_addresses, ' addresses, average street name length of ', avg_street_name_length, 
           ', and ', unique_cities, ' unique cities. Gender ', cd_gender, 
           ' has an average purchase estimate of ', avg_purchase_estimate, 
           ' from ', total_demographics, ' demographic records. Total sales amount is ', total_sales, 
           ' from ', total_orders, ' orders.') AS summary_report
FROM 
    CombinedStats
WHERE 
    total_sales > 5000  
ORDER BY 
    total_sales DESC;