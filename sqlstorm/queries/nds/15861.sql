
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    a.ca_city, 
    a.ca_state, 
    d.d_date 
FROM 
    customer c 
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk 
JOIN 
    date_dim d ON d.d_date_sk = c.c_first_sales_date_sk 
WHERE 
    d.d_year = 2023 
ORDER BY 
    c.c_last_name;
