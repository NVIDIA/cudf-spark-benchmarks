
SELECT 
    i.i_item_id,
    SUM(ss.ss_quantity) AS total_sold,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price,
    MIN(ss.ss_sales_price) AS min_sales_price
FROM 
    item i
JOIN 
    store_sales ss ON i.i_item_sk = ss.ss_item_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1 AND 365
GROUP BY 
    i.i_item_id
ORDER BY 
    total_sales DESC
LIMIT 10;
