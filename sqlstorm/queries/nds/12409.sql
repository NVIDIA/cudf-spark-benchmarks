
SELECT 
    SUM(ss_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ss_customer_sk) AS unique_customers, 
    AVG(ss_sales_price) AS average_sales_price
FROM 
    store_sales
WHERE 
    ss_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    ss_store_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
