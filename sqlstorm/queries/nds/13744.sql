
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_net_paid) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA'
AND 
    ss.ss_sold_date_sk BETWEEN 20210101 AND 20211231
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;
