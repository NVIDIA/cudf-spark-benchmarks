
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_net_paid) AS total_sales
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1 AND 30
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_sales DESC;
