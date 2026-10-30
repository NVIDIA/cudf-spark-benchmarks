
SELECT 
    ca_county,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT c_customer_id) AS unique_customers
FROM 
    store_sales
JOIN 
    customer ON ss_customer_sk = c_customer_sk
JOIN 
    customer_address ON c_current_addr_sk = ca_address_sk
WHERE 
    ss_sold_date_sk BETWEEN 2450000 AND 2450600
GROUP BY 
    ca_county
ORDER BY 
    total_net_profit DESC
LIMIT 10;
