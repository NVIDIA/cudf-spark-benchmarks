
SELECT 
    ca_city, 
    COUNT(DISTINCT c.c_customer_id) AS total_customers, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws_net_profit) AS total_net_profit
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
WHERE 
    cd.cd_gender = 'M' 
    AND cd.cd_marital_status = 'S' 
    AND ca.ca_state = 'CA'
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
GROUP BY 
    ca_city
ORDER BY 
    total_net_profit DESC
LIMIT 10;
