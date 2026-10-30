
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_returns AS sr ON sr.sr_customer_sk = c.c_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_return_amount DESC
LIMIT 100;
