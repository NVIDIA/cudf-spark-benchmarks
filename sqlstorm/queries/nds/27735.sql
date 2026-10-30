
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type || 
    CASE WHEN ca.ca_suite_number IS NOT NULL THEN ' Suite ' || ca.ca_suite_number ELSE '' END AS full_address,
    cd.cd_gender,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married' 
        WHEN cd.cd_marital_status = 'S' THEN 'Single' 
        ELSE 'Other' 
    END AS marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city = 'Los Angeles'
AND 
    cd.cd_purchase_estimate > 1000
AND 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
    ca.ca_suite_number, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_spent DESC
LIMIT 10;
