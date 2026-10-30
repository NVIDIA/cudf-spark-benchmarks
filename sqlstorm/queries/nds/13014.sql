
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity
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
    total_returns DESC
LIMIT 100;
