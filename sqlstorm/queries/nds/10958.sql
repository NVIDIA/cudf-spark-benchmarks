
SELECT 
    s_store_name, 
    SUM(ss_sales_price) AS total_sales, 
    COUNT(DISTINCT ss_ticket_number) AS transaction_count
FROM 
    store_sales
JOIN 
    store ON ss_store_sk = s_store_sk
WHERE 
    ss_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    s_store_name
ORDER BY 
    total_sales DESC
LIMIT 10;
