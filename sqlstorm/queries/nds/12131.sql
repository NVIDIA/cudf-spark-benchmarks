
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    ss.ss_sold_date_sk,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store AS s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    ss.ss_sold_date_sk >= 2450000
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, s.s_store_name, ss.ss_sold_date_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
