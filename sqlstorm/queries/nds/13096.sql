
SELECT 
    SUM(ss_sales_price) AS total_sales, 
    COUNT(ss_ticket_number) AS number_of_sales, 
    AVG(ss_sales_price) AS average_sales_price, 
    s_store_name 
FROM 
    store_sales 
JOIN 
    store ON store_sales.ss_store_sk = store.s_store_sk 
WHERE 
    ss_sold_date_sk BETWEEN 20220101 AND 20221231 
GROUP BY 
    s_store_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
