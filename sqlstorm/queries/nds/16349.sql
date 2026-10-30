
SELECT 
    c.c_customer_id, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_sales_price) AS total_revenue 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
