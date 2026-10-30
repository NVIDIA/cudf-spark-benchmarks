
SELECT 
    COUNT(*) AS total_sales,
    SUM(ss_sales_price) AS total_revenue,
    AVG(ss_sales_price) AS average_sales_price,
    MAX(ss_sales_price) AS max_sales_price,
    MIN(ss_sales_price) AS min_sales_price
FROM 
    store_sales
WHERE 
    ss_sold_date_sk BETWEEN 1 AND 365
GROUP BY 
    ss_store_sk
ORDER BY 
    total_revenue DESC
LIMIT 10;
