
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_profit) AS total_net_profit, 
    d.d_year 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2022 
GROUP BY 
    c.c_customer_id, d.d_year 
ORDER BY 
    total_net_profit DESC 
LIMIT 100;
