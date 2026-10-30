
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_sales,
    COUNT(ss.ss_ticket_number) AS transaction_count,
    a.ca_city,
    a.ca_state
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE 
    a.ca_state = 'CA' 
AND 
    ss.ss_sold_date_sk BETWEEN 2450800 AND 2451400
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    a.ca_city, 
    a.ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
