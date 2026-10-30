
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales_amount DESC 
LIMIT 100;
