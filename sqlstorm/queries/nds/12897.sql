
SELECT 
    c.c_customer_id,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(ss.ss_ticket_number) AS total_sales,
    AVG(ss.ss_net_paid) AS avg_sales_value,
    COUNT(DISTINCT ss.ss_store_sk) AS number_of_stores
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1970 AND 1990
    AND ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2020)
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_profit DESC
LIMIT 100;
