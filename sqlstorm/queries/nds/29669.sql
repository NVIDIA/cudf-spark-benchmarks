
SELECT 
    c.c_customer_id,
    CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
           CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM customer AS c
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_state IN ('CA', 'NY', 'TX', 'FL')
AND cd.cd_marital_status = 'M'
AND cd.cd_gender = 'F'
GROUP BY c.c_customer_id, c.c_salutation, c.c_first_name, c.c_last_name, 
         ca.ca_street_number, ca.ca_street_name, ca.ca_street_type,
         ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip, 
         ca.ca_country, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
HAVING COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY total_profit DESC
LIMIT 50;
