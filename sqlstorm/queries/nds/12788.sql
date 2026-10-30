
SELECT 
    c.c_customer_id, 
    s.s_store_name, 
    SUM(ss.ss_sales_price) AS total_sales 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk 
WHERE 
    s.s_state = 'CA' 
AND 
    ss.ss_sold_date_sk BETWEEN 2400 AND 2464 
GROUP BY 
    c.c_customer_id, s.s_store_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
