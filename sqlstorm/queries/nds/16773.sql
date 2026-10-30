
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_net_paid) AS total_revenue
FROM 
    customer c 
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
