
SELECT 
    cs_item_sk, 
    SUM(cs_sales_price) AS total_sales, 
    COUNT(DISTINCT cs_order_number) AS total_orders 
FROM 
    catalog_sales 
WHERE 
    cs_sold_date_sk BETWEEN 1 AND 100 
GROUP BY 
    cs_item_sk 
ORDER BY 
    total_sales DESC 
LIMIT 10;
