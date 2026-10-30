
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(ws.ws_order_number) AS total_orders
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_profit DESC
LIMIT 100;
