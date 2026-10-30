
SELECT 
    SUM(ws_net_profit) AS total_net_profit,
    d_year,
    ca_state
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    customer_address ON ws_ship_addr_sk = ca_address_sk
WHERE 
    d_year BETWEEN 2021 AND 2023
GROUP BY 
    d_year, ca_state
ORDER BY 
    d_year, total_net_profit DESC;
