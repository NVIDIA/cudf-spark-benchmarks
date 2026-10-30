
SELECT 
    c_first_name, 
    c_last_name, 
    SUM(ss_net_profit) AS total_net_profit
FROM 
    customer
JOIN 
    store_sales ON c_customer_sk = ss_customer_sk
JOIN 
    date_dim ON ss_sold_date_sk = d_date_sk
WHERE 
    d_year = 2023
GROUP BY 
    c_first_name, c_last_name
ORDER BY 
    total_net_profit DESC
LIMIT 10;
