
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    SUM(ss.ss_quantity) AS total_sales_quantity, 
    SUM(ss.ss_net_paid) AS total_net_paid
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city
ORDER BY 
    total_net_paid DESC
LIMIT 100;
