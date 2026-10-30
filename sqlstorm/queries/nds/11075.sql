
SELECT 
    c.c_customer_id, 
    SUM(ws.ws_ext_sales_price) AS total_sales, 
    COUNT(ws.ws_order_number) AS order_count 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
WHERE 
    ws.ws_sold_date_sk BETWEEN 2400 AND 2700 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales DESC 
LIMIT 10;
