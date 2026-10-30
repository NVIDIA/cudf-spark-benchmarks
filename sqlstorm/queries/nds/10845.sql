
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(sr.sr_item_sk) AS returns_count, 
    SUM(sr.sr_return_amt) AS total_return_amount
FROM 
    customer c
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN 
    date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
GROUP BY 
    c.c_first_name, 
    c.c_last_name
ORDER BY 
    total_return_amount DESC
LIMIT 10;
