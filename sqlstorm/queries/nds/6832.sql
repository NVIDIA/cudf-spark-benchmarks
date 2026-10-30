
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(sr_return_quantity) AS total_returns,
    AVG(ss_sales_price) AS avg_sales_price,
    SUM(ws_net_profit) AS total_web_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca_state
ORDER BY 
    unique_customers DESC;
