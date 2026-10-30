
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(i_current_price) AS average_item_price
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC;
