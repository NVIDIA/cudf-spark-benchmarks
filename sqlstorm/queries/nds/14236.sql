
SELECT 
    c.c_customer_id, 
    ca.ca_street_name, 
    ca.ca_city, 
    i.i_item_desc, 
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_net_paid) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'CA' 
    AND i.i_current_price > 10.00
GROUP BY 
    c.c_customer_id, 
    ca.ca_street_name, 
    ca.ca_city, 
    i.i_item_desc
ORDER BY 
    total_sales DESC
LIMIT 100;
