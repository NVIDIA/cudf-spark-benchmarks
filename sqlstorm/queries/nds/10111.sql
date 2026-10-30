
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    d.d_date, 
    s.ss_quantity, 
    s.ss_sales_price 
FROM 
    customer c 
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk 
JOIN 
    date_dim d ON s.ss_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
ORDER BY 
    d.d_date, 
    c.c_last_name;
