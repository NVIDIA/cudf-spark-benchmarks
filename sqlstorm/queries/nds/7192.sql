
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ss.ss_quantity) AS total_sales, 
    SUM(ss.ss_net_paid_inc_tax) AS total_net_sales, 
    d.d_year 
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
    AND ca.ca_state = 'CA' 
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, d.d_year 
HAVING 
    SUM(ss.ss_quantity) > 50 
ORDER BY 
    total_net_sales DESC 
LIMIT 100;
