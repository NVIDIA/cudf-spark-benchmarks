
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_quantity) AS total_quantity_sold, 
    SUM(ss.ss_net_profit) AS total_net_profit 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk 
WHERE 
    s.s_city = 'San Francisco' 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
