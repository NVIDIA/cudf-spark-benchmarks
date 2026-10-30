
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    s.s_store_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 2450000 AND 2450599
GROUP BY 
    c.c_first_name, c.c_last_name, c.c_email_address, s.s_store_name
ORDER BY 
    total_sales DESC
LIMIT 10;
