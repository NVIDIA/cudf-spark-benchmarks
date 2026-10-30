
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    SUM(ws_net_profit) AS total_net_profit
FROM 
    customer_address
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
JOIN 
    web_sales ON ws_bill_customer_sk = c_customer_sk
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
WHERE 
    d_year = 2023 
    AND ca_country = 'USA'
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
