
SELECT 
    SUM(ss_sales_price) AS total_sales, 
    COUNT(DISTINCT ss_ticket_number) AS total_transactions, 
    AVG(ss_sales_price) AS average_sales_price,
    s_store_name
FROM 
    store_sales ss
JOIN 
    store s ON ss_store_sk = s.s_store_sk
WHERE 
    ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
GROUP BY 
    s_store_name
ORDER BY 
    total_sales DESC
LIMIT 10;
