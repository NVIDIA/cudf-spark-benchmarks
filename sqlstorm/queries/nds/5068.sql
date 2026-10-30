
SELECT 
    c.c_customer_id AS customer_id,
    ca.ca_city AS customer_city,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) AS average_sales_price,
    COUNT(DISTINCT ws.ws_ship_date_sk) AS total_days_sold
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 AND 
    ws.ws_net_profit > 100
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    total_net_profit DESC
LIMIT 10;
