
SELECT 
    s_store_name,
    SUM(ss_sales_price) AS total_sales,
    COUNT(ss_ticket_number) AS total_transactions
FROM 
    store_sales 
JOIN 
    store ON store.s_store_sk = store_sales.ss_store_sk
WHERE 
    ss_sold_date_sk BETWEEN 1 AND 30
GROUP BY 
    s_store_name
ORDER BY 
    total_sales DESC
LIMIT 10;
