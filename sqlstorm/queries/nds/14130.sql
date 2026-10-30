
SELECT 
    c.c_customer_id,
    COUNT(sr.sr_item_sk) AS returns_count,
    SUM(sr.sr_return_amt) AS total_returned_amount,
    AVG(sr.sr_return_quantity) AS avg_returned_quantity
FROM 
    customer c
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_returned_amount DESC
LIMIT 10;
