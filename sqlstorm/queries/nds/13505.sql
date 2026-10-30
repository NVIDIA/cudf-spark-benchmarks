
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(wo.ws_net_profit) AS total_net_profit
FROM 
    customer c
JOIN 
    web_sales wo ON c.c_customer_sk = wo.ws_bill_customer_sk
JOIN 
    date_dim d ON wo.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_net_profit DESC
LIMIT 10;
