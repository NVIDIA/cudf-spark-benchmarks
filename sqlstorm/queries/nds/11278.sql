SELECT 
    c.c_customer_id,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
WHERE 
    s.ss_sold_date_sk BETWEEN 2451545 AND 2451547  
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;