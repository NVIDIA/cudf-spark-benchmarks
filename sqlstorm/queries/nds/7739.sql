
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ws.ws_net_profit) AS total_profit,
    ROUND(AVG(ws.ws_sales_price), 2) AS average_sales_price,
    MAX(ws.ws_ext_sales_price) AS max_sales_price,
    MIN(ws.ws_ext_sales_price) AS min_sales_price
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
JOIN 
    time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    dd.d_year = 2023 AND 
    sm.sm_type LIKE 'Ground%'
GROUP BY 
    ca.ca_city
ORDER BY 
    total_profit DESC
LIMIT 10;
