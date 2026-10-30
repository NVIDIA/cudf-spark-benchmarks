
SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    SUM(ss.ss_quantity) AS total_quantity_sold, 
    SUM(ss.ss_net_paid) AS total_net_paid
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, 
    ca.ca_city
ORDER BY 
    total_net_paid DESC
LIMIT 100;
