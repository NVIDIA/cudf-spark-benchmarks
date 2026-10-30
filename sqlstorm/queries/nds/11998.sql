
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_date, 
    SUM(ss.ss_net_profit) AS total_net_profit 
FROM 
    store_sales ss 
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_date 
ORDER BY 
    total_net_profit DESC 
LIMIT 100;
