
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
    SUM(ws.ws_sales_price) AS total_web_spent,
    SUM(ss.ss_sales_price) AS total_store_spent,
    MAX(ws.ws_sold_date_sk) AS last_web_order_date,
    MAX(ss.ss_sold_date_sk) AS last_store_order_date
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_city IS NOT NULL AND
    ca.ca_state IS NOT NULL AND
    (ws.ws_sales_price > 0 OR ss.ss_sales_price > 0)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    (total_web_spent + total_store_spent) DESC
LIMIT 10;
