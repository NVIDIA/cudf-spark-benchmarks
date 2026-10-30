
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_suite_number IS NOT NULL THEN 1 ELSE 0 END) AS suites_present
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemoStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_credit_rating) AS unique_credit_ratings
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_ship_mode_sk
),
FinalStats AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.avg_street_name_length,
        a.suites_present,
        d.cd_gender,
        d.total_demographics,
        d.avg_purchase_estimate,
        d.unique_credit_ratings,
        s.total_quantity,
        s.avg_sales_price
    FROM 
        AddressStats a
        JOIN DemoStats d ON a.total_addresses > 100
        JOIN SalesStats s ON s.total_quantity > 500
)
SELECT 
    ca_state,
    SUM(total_addresses) AS aggregate_addresses,
    AVG(avg_street_name_length) AS average_street_name_length,
    SUM(suites_present) AS total_suites,
    MAX(cd_gender) AS predominant_gender,
    SUM(total_demographics) AS grand_total_demographics,
    AVG(avg_purchase_estimate) AS average_purchase_estimate,
    COUNT(DISTINCT unique_credit_ratings) AS distinct_credit_ratings_count,
    SUM(total_quantity) AS aggregate_quantity,
    AVG(avg_sales_price) AS average_sales_price
FROM 
    FinalStats
GROUP BY 
    ca_state
ORDER BY 
    aggregate_addresses DESC;
