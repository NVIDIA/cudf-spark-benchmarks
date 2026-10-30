
SELECT 
    c.c_customer_id,
    COUNT(sr.sr_return_quantity) AS total_returns,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_value
FROM 
    customer c
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN 
    item i ON sr.sr_item_sk = i.i_item_sk
JOIN 
    date_dim d ON d.d_date_sk = sr.sr_returned_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_return_value DESC
LIMIT 10;
