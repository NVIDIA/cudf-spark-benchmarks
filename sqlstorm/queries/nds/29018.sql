
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        REPLACE(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip), 'NULL', '') AS address,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)

SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    address,
    COUNT(ws_order_number) AS total_orders,
    SUM(ws_net_profit) AS total_profit,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    address
HAVING 
    SUM(ws_net_profit) > 5000
ORDER BY 
    total_profit DESC
LIMIT 10;
