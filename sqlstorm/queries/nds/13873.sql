
SELECT 
    c.c_customer_id, 
    COUNT(DISTINCT sr_ticket_number) AS total_returns, 
    SUM(sr_return_amt_inc_tax) AS total_return_amount
FROM 
    customer c
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN 
    date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2022
GROUP BY 
    c.c_customer_id
HAVING 
    COUNT(DISTINCT sr_ticket_number) > 5
ORDER BY 
    total_returns DESC
LIMIT 100;
