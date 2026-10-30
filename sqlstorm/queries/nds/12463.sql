
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    COUNT(DISTINCT sr_item_sk) AS total_returns,
    SUM(sr_return_amt) AS total_return_amount
FROM 
    customer_address
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
LEFT JOIN 
    store_returns ON c_customer_sk = sr_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_return_amount DESC
LIMIT 10;
