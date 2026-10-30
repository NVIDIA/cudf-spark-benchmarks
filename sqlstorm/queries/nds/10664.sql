
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS total_transactions 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = 'CA') 
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales DESC 
LIMIT 100;
