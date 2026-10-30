
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_profit) AS total_net_profit 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    c.c_birth_month = 12 
    AND c.c_current_cdemo_sk IS NOT NULL 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
