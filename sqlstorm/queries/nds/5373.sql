
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ws.ws_quantity) AS total_quantity, 
    SUM(ws.ws_sales_price) AS total_sales, 
    AVG(ws.ws_net_profit) AS average_net_profit 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
    AND ca.ca_state IN ('CA', 'TX', 'NY') 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state 
HAVING 
    SUM(ws.ws_quantity) > 10 
ORDER BY 
    total_sales DESC 
LIMIT 50;
