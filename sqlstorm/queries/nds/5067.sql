
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_sales_price) AS total_sales,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(ws_net_profit) AS max_online_profit,
    MIN(ss_net_profit) AS min_store_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
AND 
    ss_sold_date_sk BETWEEN 1000 AND 2000
AND 
    ws_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_sk) > 10
ORDER BY 
    total_sales DESC
LIMIT 5;
