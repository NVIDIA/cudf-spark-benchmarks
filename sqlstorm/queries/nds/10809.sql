
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ss.ss_quantity,
    ss.ss_sales_price,
    d.d_date,
    t.t_hour
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE 
    d.d_year = 2023 
    AND ca.ca_state = 'CA'
ORDER BY 
    ss.ss_sales_price DESC
LIMIT 100;
