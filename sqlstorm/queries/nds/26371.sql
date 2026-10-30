
SELECT 
    c.c_first_name,
    c.c_last_name,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_last_name
        WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_last_name
        ELSE c.c_last_name
    END AS salutation,
    COUNT(DISTINCT(ws_order_number)) AS total_orders,
    SUM(ws_sales_price) AS total_spent,
    AVG(ws_sales_price) AS average_order_value
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city LIKE '%York%'
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_street_number, 
    ca.ca_street_name, 
    ca.ca_street_type, 
    cd.cd_gender
ORDER BY 
    total_spent DESC 
LIMIT 10;
