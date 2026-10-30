
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    s.s_store_name, 
    ss.ss_sales_price, 
    ss.ss_sold_date_sk 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk 
WHERE 
    ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231 
ORDER BY 
    ss.ss_sales_price DESC 
LIMIT 100;
