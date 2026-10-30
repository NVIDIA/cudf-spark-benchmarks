
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN 1 AND 31
    AND ws_ship_date_sk IS NOT NULL
GROUP BY 
    ws_web_site_sk
ORDER BY 
    total_sales DESC;
