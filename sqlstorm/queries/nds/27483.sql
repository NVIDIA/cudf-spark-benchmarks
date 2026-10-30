
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    MAX(i.i_current_price) AS highest_item_price,
    AVG(i.i_current_price) AS average_item_price
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON i.i_item_sk = COALESCE(ws.ws_item_sk, ss.ss_item_sk)
WHERE 
    ca.ca_state IN ('NY', 'CA', 'TX') 
    AND cd.cd_gender = 'F'
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_web_sales DESC, unique_customers DESC;
