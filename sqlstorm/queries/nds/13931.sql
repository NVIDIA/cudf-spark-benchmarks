
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_net_paid) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS total_transactions, 
    AVG(ss.ss_net_paid) AS average_transaction_value 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    ss.ss_sold_date_sk BETWEEN 2451517 AND 2451653 
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name 
ORDER BY 
    total_sales DESC 
LIMIT 100;
