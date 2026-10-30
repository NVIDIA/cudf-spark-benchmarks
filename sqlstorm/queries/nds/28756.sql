
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    REPLACE(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip), '  ', ' ') AS address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    (SELECT COUNT(DISTINCT ss.ss_ticket_number) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_purchases,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_purchases,
    (SELECT SUM(ss.ss_net_paid) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_spent,
    (SELECT SUM(ws.ws_net_paid) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_spent
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND cd.cd_education_status LIKE '%Graduate%'
ORDER BY 
    total_store_spent DESC, 
    total_web_spent DESC
LIMIT 100;
