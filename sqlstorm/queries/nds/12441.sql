
SELECT 
    cs_item_sk, 
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_sales_price) AS total_sales,
    AVG(cs_net_profit) AS average_net_profit
FROM 
    catalog_sales
WHERE 
    cs_sold_date_sk BETWEEN 2451877 AND 2451938
GROUP BY 
    cs_item_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
