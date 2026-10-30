
SELECT 
    cs_item_sk, 
    SUM(cs_quantity) AS total_sales_quantity, 
    SUM(cs_ext_sales_price) AS total_sales_amount
FROM 
    catalog_sales
WHERE 
    cs_sold_date_sk BETWEEN 2450000 AND 2450600
GROUP BY 
    cs_item_sk
ORDER BY 
    total_sales_quantity DESC
LIMIT 100;
