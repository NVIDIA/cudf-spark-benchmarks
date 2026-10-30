
SELECT 
    c.c_customer_id,
    SUM(ws.ws_net_paid) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_web_pages
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 2459582 AND 2459664 
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
