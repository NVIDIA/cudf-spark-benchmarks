
SELECT 
    c.c_customer_id, 
    COUNT(sr.sr_return_quantity) AS total_returns, 
    SUM(sr.sr_return_amt) AS total_return_amount, 
    MAX(sr.sr_return_time_sk) AS last_return_time
FROM 
    customer c
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_returns DESC
LIMIT 100;
