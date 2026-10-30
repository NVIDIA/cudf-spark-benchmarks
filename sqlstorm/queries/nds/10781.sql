SELECT 
    COUNT(*) AS total_sales,
    SUM(ss_net_paid) AS total_revenue,
    AVG(ss_net_profit) AS average_profit,
    s_store_name
FROM 
    store_sales ss
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 2459302 AND 2459330  
GROUP BY 
    s_store_name
ORDER BY 
    total_sales DESC
LIMIT 10;