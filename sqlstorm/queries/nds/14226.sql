SELECT 
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(ss_ticket_number) AS total_transactions,
    AVG(ss_sales_price) AS average_sale_price
FROM 
    store_sales
WHERE 
    ss_sold_date_sk = 2459607 
GROUP BY 
    ss_store_sk
ORDER BY 
    total_sales DESC
LIMIT 10;