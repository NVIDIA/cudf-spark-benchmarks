
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    COUNT(DISTINCT ws.ws_order_number) AS total_online_orders, 
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
    SUM(ws.ws_net_paid) AS total_online_sales, 
    SUM(ss.ss_net_paid) AS total_store_sales,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    INITCAP(ca.ca_city) AS formatted_city,
    LENGTH(c.c_email_address) AS email_length,
    SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1, LENGTH(c.c_email_address)) AS email_domain
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, c.c_email_address
ORDER BY 
    total_online_sales DESC, total_store_sales DESC;
