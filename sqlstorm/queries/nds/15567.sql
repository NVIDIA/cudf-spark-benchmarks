
SELECT 
    SUM(ss_sales_price) AS total_sales
FROM 
    store_sales
WHERE 
    ss_sold_date_sk BETWEEN 1 AND 100
GROUP BY 
    ss_store_sk
ORDER BY 
    total_sales DESC;
