
SELECT 
    c.c_customer_id,
    ca.ca_city,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2022
GROUP BY 
    c.c_customer_id, ca.ca_city, c.c_first_name, c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 100;
