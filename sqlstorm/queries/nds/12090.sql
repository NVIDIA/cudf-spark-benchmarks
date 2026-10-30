
SELECT 
    c_first_name, 
    c_last_name, 
    SUM(ws_net_profit) AS total_net_profit
FROM 
    customer 
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk
WHERE 
    c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c_first_name, c_last_name
ORDER BY 
    total_net_profit DESC
LIMIT 100;
