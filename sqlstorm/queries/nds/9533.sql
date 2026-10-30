
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    d.d_year,
    r.r_reason_desc
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    web_returns wr ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN 
    reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, d.d_year, r.r_reason_desc
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY 
    total_sales DESC, c.c_last_name ASC;
