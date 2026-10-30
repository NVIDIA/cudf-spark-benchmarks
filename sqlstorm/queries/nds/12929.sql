
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ss.ss_quantity) AS total_sales_quantity,
    SUM(ss.ss_net_paid) AS total_net_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ss.ss_sold_date_sk BETWEEN 2459475 AND 2459480
GROUP BY 
    ca.ca_city
ORDER BY 
    total_net_sales DESC
LIMIT 10;
