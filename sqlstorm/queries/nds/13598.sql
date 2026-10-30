
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_paid) AS total_sales
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 10;
