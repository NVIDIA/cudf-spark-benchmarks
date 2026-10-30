
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
    SUM(s.ss_sales_price) AS total_revenue
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_revenue DESC
LIMIT 10;
