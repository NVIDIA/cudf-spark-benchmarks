
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    d.d_date, 
    ss.ss_quantity, 
    ss.ss_sales_price 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
    AND ss.ss_sales_price > 100 
ORDER BY 
    d.d_date DESC, 
    ss.ss_sales_price DESC 
LIMIT 100;
