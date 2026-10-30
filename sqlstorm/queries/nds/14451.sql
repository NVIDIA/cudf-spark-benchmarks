
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(cs.cs_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 100;
