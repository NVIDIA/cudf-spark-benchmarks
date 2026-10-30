
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    count(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    SUM(ws.ws_net_profit) AS total_profit,
    DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS gender_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city LIKE '%New York%'
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
