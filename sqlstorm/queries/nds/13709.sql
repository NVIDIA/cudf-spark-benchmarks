
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(w.ws_ext_sales_price) AS total_sales,
    AVG(i.i_current_price) AS avg_item_price
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
JOIN 
    item i ON w.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'NY'
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
