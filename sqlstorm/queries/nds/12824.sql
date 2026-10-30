
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item AS i ON ss.ss_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'NY' 
    AND i.i_current_price > 20.00
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ss.ss_net_profit) > 1000.00
ORDER BY 
    total_net_profit DESC;
