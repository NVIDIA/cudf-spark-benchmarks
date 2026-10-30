
SELECT 
    COUNT(*) AS total_sales,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(ss_sales_price) AS average_sales_price,
    MAX(ss_net_paid) AS max_net_paid,
    MIN(ss_net_paid) AS min_net_paid
FROM 
    store_sales
WHERE 
    ss_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    ss_store_sk
ORDER BY 
    total_net_profit DESC
LIMIT 10;
