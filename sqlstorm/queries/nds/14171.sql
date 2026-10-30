
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(ws_net_profit) AS total_net_profit
FROM 
    customer_address 
JOIN 
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN 
    web_sales ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
