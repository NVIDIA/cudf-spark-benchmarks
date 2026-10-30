
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_spent,
    COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
    d.d_year
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2022
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_year
ORDER BY 
    total_spent DESC
LIMIT 100;
