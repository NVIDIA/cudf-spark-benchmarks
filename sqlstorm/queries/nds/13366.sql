
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    a.ca_state,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer AS c
JOIN 
    customer_address AS a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;
