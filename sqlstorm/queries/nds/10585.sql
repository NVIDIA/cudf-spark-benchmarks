
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_quantity) AS total_sales,
    SUM(ss.ss_net_paid) AS total_net_paid
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name, c.c_last_name
HAVING 
    SUM(ss.ss_quantity) > 100
ORDER BY 
    total_net_paid DESC
LIMIT 10;
