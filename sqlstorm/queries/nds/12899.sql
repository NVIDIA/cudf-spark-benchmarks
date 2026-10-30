
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_count,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_sales_price) AS average_sales_price,
    COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
    SUM(sr.sr_return_amt) AS total_returns,
    AVG(sr.sr_return_amt) AS average_return_amount
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
