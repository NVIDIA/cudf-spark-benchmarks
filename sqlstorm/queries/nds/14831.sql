
SELECT 
    ca_street_name, 
    ca_city, 
    cd_gender, 
    cd_marital_status, 
    SUM(ws_quantity) AS total_sales
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    cd_marital_status = 'M' 
    AND cd_gender = 'F' 
    AND ca_state = 'CA'
GROUP BY 
    ca_street_name, 
    ca_city, 
    cd_gender, 
    cd_marital_status
ORDER BY 
    total_sales DESC
LIMIT 10;
