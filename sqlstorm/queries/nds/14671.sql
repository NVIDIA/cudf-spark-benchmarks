
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ss_net_paid) AS total_revenue
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca_state = 'CA' 
    AND ss.ss_sold_date_sk BETWEEN 2451015 AND 2451649
GROUP BY 
    ca_city
ORDER BY 
    total_revenue DESC
LIMIT 10;
