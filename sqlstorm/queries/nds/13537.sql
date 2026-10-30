
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS total_customers, 
    SUM(ss_net_profit) AS total_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ca_city
ORDER BY 
    total_profit DESC
LIMIT 10;
