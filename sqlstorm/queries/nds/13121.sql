
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ss.ss_sales_price) AS total_sales,
    d.d_year,
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
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, d.d_year, t.t_hour
ORDER BY 
    total_sales DESC
LIMIT 10;
