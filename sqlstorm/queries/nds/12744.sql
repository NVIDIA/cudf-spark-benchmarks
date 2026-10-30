SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    sum(ss.ss_net_profit) AS total_net_profit 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    ss.ss_sold_date_sk BETWEEN 2450122 AND 2450125 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name 
ORDER BY 
    total_net_profit DESC 
LIMIT 100;