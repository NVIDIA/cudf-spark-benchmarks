
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    s.s_state = 'CA' AND 
    ss.ss_sold_date_sk BETWEEN 2459120 AND 2459480
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 10;
