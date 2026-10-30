
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
FROM 
    web_sales 
WHERE 
    ws_sold_date_sk BETWEEN 20210101 AND 20211231 
GROUP BY 
    ws_ship_mode_sk
ORDER BY 
    total_sales DESC;
