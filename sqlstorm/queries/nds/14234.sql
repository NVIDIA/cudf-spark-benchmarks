SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 2451545 AND 2451880 
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;