
SELECT 
    c.c_customer_sk,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
