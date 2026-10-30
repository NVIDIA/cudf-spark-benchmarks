
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(sr.sr_item_sk) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_return_amount DESC;
