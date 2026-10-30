
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS total_customers,
    SUM(ws_net_paid) AS total_sales,
    AVG(ws_net_paid) AS avg_order_value,
    MAX(ws_net_profit) AS max_order_profit,
    MIN(ws_net_profit) AS min_order_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 AND 
    ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca_city, ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
