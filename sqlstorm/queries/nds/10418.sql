
SELECT 
    c.c_customer_id,
    sum(ss.ss_sales_price) as total_sales,
    count(ss.ss_ticket_number) as total_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 20230101 AND 20230131
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
