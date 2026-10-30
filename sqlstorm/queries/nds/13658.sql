
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(sr.sr_return_tax) AS total_return_tax
FROM 
    customer AS c
JOIN 
    store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN 
    date_dim AS dd ON sr.sr_returned_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_returns DESC
LIMIT 100;
