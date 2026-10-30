
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    s.s_store_name, 
    ss.ss_sales_price, 
    ss.ss_quantity, 
    d.d_date 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk 
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
    AND s.s_state = 'CA' 
ORDER BY 
    ss.ss_sales_price DESC 
LIMIT 100;
