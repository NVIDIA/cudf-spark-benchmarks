
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers,
    AVG(ws_net_paid_inc_tax) AS average_order_value
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN 2450000 AND 2450050
GROUP BY 
    ws_web_site_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
