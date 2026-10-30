
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS num_customers, 
    SUM(ws_net_paid) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC;
