
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT sr_ticket_number) AS total_returns,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_return_tax) AS total_return_tax
FROM 
    customer c
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_returns DESC
LIMIT 100;
