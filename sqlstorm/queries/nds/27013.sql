WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_name) + LENGTH(ca_city)) AS total_length,
        AVG(LENGTH(ca_street_name) + LENGTH(ca_city)) AS avg_length,
        MAX(LENGTH(ca_street_name) + LENGTH(ca_city)) AS max_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemoSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS sale_transactions,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(CASE WHEN ws_quantity > 10 THEN 1 ELSE 0 END) AS bulk_sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.total_length,
    a.avg_length,
    a.max_length,
    d.cd_gender,
    d.customer_count,
    d.avg_purchase,
    d.married_count,
    d.single_count,
    s.ws_sold_date_sk,
    s.total_sales,
    s.sale_transactions,
    s.avg_sales_price,
    s.bulk_sales_count
FROM 
    AddressSummary a
JOIN 
    DemoSummary d ON d.customer_count > 100 
JOIN 
    SalesSummary s ON s.total_sales > 1000 
ORDER BY 
    a.unique_addresses DESC, 
    s.total_sales DESC;