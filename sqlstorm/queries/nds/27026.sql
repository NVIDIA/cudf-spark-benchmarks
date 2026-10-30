WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        SUM(cd_dep_college_count) AS college_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    d.cd_gender,
    d.total_demographics,
    d.total_dependents,
    d.employed_dependents,
    d.college_dependents,
    s.ws_sold_date_sk,
    s.total_sales,
    s.total_orders,
    s.unique_customers
FROM 
    AddressStats a
JOIN 
    DemographicCounts d ON 1=1  
JOIN 
    SalesSummary s ON 1=1        
WHERE 
    a.total_addresses > 1000 
    AND d.total_demographics > 500
    AND s.total_sales > 10000
ORDER BY 
    a.ca_state, d.cd_gender, s.ws_sold_date_sk DESC;