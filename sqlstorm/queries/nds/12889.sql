SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_paid) AS total_net_paid
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600 
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_paid DESC
LIMIT 100;