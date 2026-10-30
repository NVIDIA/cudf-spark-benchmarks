
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    sa.ca_city, 
    sa.ca_state, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_net_paid) AS total_revenue 
FROM 
    customer c 
JOIN 
    customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    sa.ca_state = 'CA' 
GROUP BY 
    c.c_first_name, c.c_last_name, sa.ca_city, sa.ca_state 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
