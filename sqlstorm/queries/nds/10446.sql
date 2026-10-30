
SELECT 
    COUNT(*) AS total_sales,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(ss_sales_price) AS average_sales_price,
    MAX(ss_sales_price) AS max_sales_price,
    MIN(ss_sales_price) AS min_sales_price,
    SUM(ss_quantity) AS total_quantity_sold
FROM 
    store_sales
WHERE 
    ss_sold_date_sk BETWEEN 5000 AND 6000;
