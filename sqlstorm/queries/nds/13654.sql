
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    s.s_store_name, 
    SUM(ss.ss_sales_price) AS total_sales 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk 
WHERE 
    c.c_current_addr_sk IS NOT NULL 
GROUP BY 
    c.c_first_name, c.c_last_name, s.s_store_name 
ORDER BY 
    total_sales DESC 
LIMIT 100;
