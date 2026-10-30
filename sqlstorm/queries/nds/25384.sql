
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        AVG(LENGTH(ca_city)) AS avg_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesStats AS (
    SELECT 
        CASE 
            WHEN ws_sales_price < 20 THEN 'Low'
            WHEN ws_sales_price BETWEEN 20 AND 50 THEN 'Medium'
            ELSE 'High'
        END AS sales_category,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        sales_category
),
FinalBenchmark AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.avg_street_name_length,
        a.avg_city_length,
        s.sales_category,
        s.total_sales,
        s.total_net_profit
    FROM 
        AddressStats a
    JOIN 
        SalesStats s ON a.total_addresses > 100
)
SELECT 
    ca_state,
    total_addresses,
    avg_street_name_length,
    avg_city_length,
    sales_category,
    total_sales,
    total_net_profit
FROM 
    FinalBenchmark
WHERE 
    total_net_profit > 1000
ORDER BY 
    total_net_profit DESC, total_addresses DESC;
