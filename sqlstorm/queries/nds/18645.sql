
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_net_paid) AS total_revenue
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
ORDER BY 
    total_revenue DESC
LIMIT 10;
