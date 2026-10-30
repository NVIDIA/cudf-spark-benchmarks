
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers,
    COUNT(DISTINCT ws_item_sk) AS unique_items
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
GROUP BY 
    ws_web_site_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
