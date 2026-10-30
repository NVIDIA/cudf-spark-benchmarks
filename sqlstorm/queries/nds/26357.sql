
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               COALESCE(CONCAT(' Suite ', TRIM(ca_suite_number)), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
aggregated_sales AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    pa.full_address,
    pa.ca_city,
    pa.ca_state,
    pa.ca_zip,
    COALESCE(asales.total_sales, 0) AS total_sales,
    COALESCE(asales.total_orders, 0) AS total_orders,
    COALESCE(asales.unique_items_sold, 0) AS unique_items_sold
FROM 
    processed_addresses pa
LEFT JOIN 
    aggregated_sales asales ON pa.ca_address_sk = asales.ws_bill_addr_sk
WHERE 
    UPPER(pa.ca_city) LIKE 'NEW%' 
ORDER BY 
    total_sales DESC 
LIMIT 100;
