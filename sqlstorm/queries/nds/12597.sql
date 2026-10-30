
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.ss_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 AND
    d.d_moy BETWEEN 1 AND 6
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_profit DESC
LIMIT 10;
