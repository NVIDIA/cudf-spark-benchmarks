
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    AVG(ss.ss_sales_price) AS avg_sales_price
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number 
WHERE 
    c.c_current_cdemo_sk IS NOT NULL 
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
