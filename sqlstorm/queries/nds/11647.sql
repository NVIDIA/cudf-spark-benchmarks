
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ss_net_profit) AS total_net_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales AS ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    date_dim AS d ON d.d_date_sk = ss.ss_sold_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ca_city
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
