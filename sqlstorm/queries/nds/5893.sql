SELECT 
    ca_state, 
    COUNT(*) AS total_customers, 
    SUM(ws_net_paid) AS total_sales, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales AS ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_country = 'USA' 
    AND ws_sold_date_sk BETWEEN 2459808 AND 2459840  
GROUP BY 
    ca_state
HAVING 
    COUNT(*) > 50
ORDER BY 
    total_sales DESC
LIMIT 10;