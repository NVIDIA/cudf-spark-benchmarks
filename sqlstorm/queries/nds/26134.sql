
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    SUBSTRING(ca.ca_street_name, 1, 10) AS short_street_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city LIKE '%York%' 
    AND cd.cd_gender = 'M'
    AND cd.cd_purchase_estimate > 1000
GROUP BY 
    full_name, ca.ca_city, ca.ca_state, short_street_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_sales DESC
LIMIT 10;
